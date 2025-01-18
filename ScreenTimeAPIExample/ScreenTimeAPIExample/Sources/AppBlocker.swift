import Foundation
import ManagedSettings
import DeviceActivity
import CoreMotion
import Combine
import UserNotifications

extension DeviceActivityName {
    static let once = Self("once")
    static let daily = Self("daily")
}

class AppBlocker: ObservableObject {
    static let shared = AppBlocker()
    
    let store: ManagedSettingsStore
    let model: BlockingApplicationModel
    var blockStartHour: Int
    var blockStartMinute: Int
    var blockEndHour: Int
    var blockEndMinute: Int

    @Published var activeSchedules: Set<BlockSchedule> = [] {
        didSet {
            saveActiveSchedules()
        }
    }
    
    private var isTemporarilyUnblocked: Bool = false
    
    @Published var stepCount: Int = 0 {
        willSet {
            print("Updating stepCount to: \(newValue)")
        }
    }
    
    private var pedometer: CMPedometer?
    private var hasReachedGoal: Bool = false
    
    @Published var isWithinSchedule: Bool = false
    private var scheduleTimer: Timer?
    
    @Published var showActiveSchedulesAlert: Bool = false
    var activeSchedulesText: String = ""

    private let activeSchedulesKey = "ActiveSchedules"

    init() {
        self.store = ManagedSettingsStore()
        self.model = BlockingApplicationModel.shared
        self.blockStartHour = 0
        self.blockStartMinute = 0
        self.blockEndHour = 0
        self.blockEndMinute = 0
        self.pedometer = CMPedometer()
        loadActiveSchedules()
    }
    
    // Save active schedules to UserDefaults
    private func saveActiveSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: BlockingApplicationModel.appGroupID) else { return }
        do {
            let encodedData = try JSONEncoder().encode(Array(activeSchedules))
            groupUserDefaults.set(encodedData, forKey: activeSchedulesKey)
            groupUserDefaults.synchronize()
        } catch {
            print("❌ Failed to encode active schedules: \(error)")
        }
    }
    
    // Load active schedules from UserDefaults
    private func loadActiveSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: BlockingApplicationModel.appGroupID) else { return }
        if let data = groupUserDefaults.data(forKey: activeSchedulesKey),
           let decoded = try? JSONDecoder().decode([BlockSchedule].self, from: data) {
            activeSchedules = Set(decoded)
        }
    }
    
    // Initialize timer for blocking
    var timer: Timer?
    
    func startBlockingSchedule(schedule: BlockSchedule) {
        print("🔄 Starting blocking for schedule: \(schedule.formattedStartTime()) - \(schedule.formattedEndTime())")
        
        // Add to active schedules
        activeSchedules.insert(schedule)

        let deviceActivityCenter = DeviceActivityCenter()
        
        // Create the schedule components
        var startComponents = DateComponents()
        startComponents.hour = schedule.startHour
        startComponents.minute = schedule.startMinute
        
        var endComponents = DateComponents()
        endComponents.hour = schedule.endHour
        endComponents.minute = schedule.endMinute
        
        let deviceSchedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )
        
        do {
            let activityName = DeviceActivityName("schedule_\(schedule.id.uuidString)")
            try deviceActivityCenter.startMonitoring(activityName, during: deviceSchedule)
            
            // If we're currently within the schedule, block immediately
            if isCurrentTimeInBlockWindow(currentDate: Date(),
                                        blockStartHour: schedule.startHour,
                                        blockStartMinute: schedule.startMinute,
                                        blockEndHour: schedule.endHour,
                                        blockEndMinute: schedule.endMinute) {
                print("📱 Currently within schedule window - blocking apps")
                // This is not technically needed, since startMonitoring will block
                // but this makes it instant, while startMonitoring can have a bit of delay
                store.shield.applications = model.selectedAppsTokens
            } else {
                print("⏳ Outside schedule window - waiting for start time")
            }
            
            print("✅ Monitoring started successfully")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }

    func removeSchedule(schedule: BlockSchedule) {
        activeSchedules.remove(schedule)
        let deviceActivityCenter = DeviceActivityCenter()
        let activityName = DeviceActivityName("schedule_\(schedule.id.uuidString)")
        deviceActivityCenter.stopMonitoring([activityName])
        
        // Check if we should unblock apps
        if !isCurrentlyInAnyBlockWindow() && !isTemporarilyUnblocked {
            unblockAllApps()
        }
    }

    func isCurrentlyInAnyBlockWindow() -> Bool {
        let currentDate = Date()
        return activeSchedules.contains { schedule in
            isCurrentTimeInBlockWindow(
                currentDate: currentDate,
                blockStartHour: schedule.startHour,
                blockStartMinute: schedule.startMinute,
                blockEndHour: schedule.endHour,
                blockEndMinute: schedule.endMinute
            )
        }
    }
    
    func isCurrentTimeInBlockWindow(currentDate: Date,
                                  blockStartHour: Int,
                                  blockStartMinute: Int,
                                  blockEndHour: Int,
                                  blockEndMinute: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: currentDate)
        guard let currentHour = components.hour,
              let currentMinute = components.minute else {
            return false
        }
        
        let currentTime = currentHour * 60 + currentMinute
        let startTime = blockStartHour * 60 + blockStartMinute
        let endTime = blockEndHour * 60 + blockEndMinute
        
        if endTime < startTime {
            return currentTime >= startTime || currentTime <= endTime
        } else {
            return currentTime >= startTime && currentTime <= endTime
        }
    }

    func stopMonitoring() {
        let deviceActivityCenter = DeviceActivityCenter()
        deviceActivityCenter.stopMonitoring([.daily])
        print("🛑 Stopped monitoring device activity")
    }
    
    // Function to schedule unblock timer
    private func scheduleUnblockTimer(after timeInterval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.unblockAllApps()
        }
    }
    
    private func scheduleBlockNotification(after timeInterval: TimeInterval) {
        print("Scheduling a timer block")
        
        // Schedule the notification
        let content = UNMutableNotificationContent()
        content.title = "App Block Warning"
        if(timeInterval > 100) {
            content.body = "The app will be blocked in 1 minute"
        } else {
            content.body = "The app will be blocked in 5 seconds"
        }
        content.sound = .default
        
        // Trigger notification 1 minute before blocking
        let triggerTime = if timeInterval > 100 {
            timeInterval - 60 // 1 minute before block
        } else {
            timeInterval - 5  // 5 seconds before block
        }
        if triggerTime > 0 {
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            let request = UNNotificationRequest(identifier: "blockWarning", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }

    // Function to unblock all apps
    func unblockAllApps() {
        store.shield.applications = []
    }

    func unblockWithDeviceActivity(forDuration seconds: TimeInterval, blockEndHour: Int, blockEndMinute: Int) {
        guard !activeSchedules.isEmpty else { return }

        let deviceActivityCenter = DeviceActivityCenter()
        isTemporarilyUnblocked = true

        self.scheduleBlockNotification(after: seconds);
        
        // Calculate the start time after the delay
        let now = Date()
        let startDate = now.addingTimeInterval(seconds)
        
        // Extract the start time components
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startDate)
        
        // Create the end time components
        var endComponents = DateComponents()
        endComponents.hour = blockEndHour
        endComponents.minute = blockEndMinute
        
        // Create the activity schedule
        let tempSchedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false
        )
        
        do {
            // Stop all active schedules temporarily
            let activeActivityNames = activeSchedules.map { DeviceActivityName("schedule_\($0.id.uuidString)") }
            deviceActivityCenter.stopMonitoring(activeActivityNames)

            try deviceActivityCenter.startMonitoring(.once, during: tempSchedule)
            print("🔄 Monitor extension will start after \(seconds) seconds and run until \(blockEndHour):\(blockEndMinute).")

            // Schedule reinstatement of all original schedules
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds + 1) { [weak self] in
                guard let self = self else { return }
                self.isTemporarilyUnblocked = false
                
                // Restart all active schedules
                for schedule in self.activeSchedules {
                    self.startBlockingSchedule(schedule: schedule)
                }
            }
        } catch {
            print("❌ Failed to configure monitor extension: \(error)")
        }
    }

    
    func unblockTemp() {
        hasReachedGoal = false
        if CMPedometer.isStepCountingAvailable() {
            // Reset step count when starting
            DispatchQueue.main.async {
                self.stepCount = 0
            }
            
            let startTime = Date()
            // Start counting steps with more frequent updates
            pedometer?.startUpdates(from: startTime, withHandler: { [weak self] pedometerData, error in
                guard let self = self else { return }
                guard !self.hasReachedGoal else { return }
                
                guard let data = pedometerData, error == nil else {
                    print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let steps = data.numberOfSteps.intValue
                print("Raw steps from pedometer: \(steps)")
                
                // Ensure UI update happens on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.stepCount = steps
                    print("Step count after update: \(self.stepCount)")
                    
                    if steps >= 15 && !self.hasReachedGoal {
                        self.hasReachedGoal = true
                        self.pedometer?.stopUpdates()
                        // Show the final step count for a moment before unblocking
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.unblockApplicationsTemporarily5minutes()
                        }
                    }
                }
            })
        }
    }

    func unblockApplicationsTemporarily5minutes() {
        print("🔓 Temporarily unblocking apps")
        self.unblockAllApps()

        // Schedule reblock after 300 seconds
        unblockWithDeviceActivity(forDuration: 300, blockEndHour: blockEndHour, blockEndMinute: blockEndMinute)
        // Reset step count after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.stepCount = 0
        }
    }
    
    // for debugging
    func unblockApplicationsTemporarily15seconds() {
        print("🔓 Temporarily unblocking apps")
        self.unblockAllApps()

        // Schedule reblock after 15 seconds
        unblockWithDeviceActivity(forDuration: 15, blockEndHour: blockEndHour, blockEndMinute: blockEndMinute)
        // Reset step count after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.stepCount = 0
        }
    }
    
    // Enum for error handling
    enum BlockerError: Error {
        case invalidTimeWindow
        case outsideTimeWindow
        case invalidTimeZone
    }
    
    func isCurrentTimeEqualToDateUpToMinute(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.hour, .minute], from: date2)
        return components1 == components2
    }

    // Don't forget to clean up
    func stopStepCountUpdates() {
        pedometer?.stopUpdates()
        hasReachedGoal = false
        DispatchQueue.main.async {
            self.stepCount = 0
        }
    }

    // Replacement to checkAndUnblockForDeletedSchedule
    func removeAndCheckSchedule(_ deletedSchedule: BlockSchedule) {
        print("🔄 Removing schedule and checking block status...")
        
        // Remove from active schedules
        activeSchedules.remove(deletedSchedule)

        print("Here 1")
        
        // Stop monitoring for this specific schedule
        let deviceActivityCenter = DeviceActivityCenter()
        let activityName = DeviceActivityName("schedule_\(deletedSchedule.id.uuidString)")
        deviceActivityCenter.stopMonitoring([activityName])

        print("Here 2")
        
        // Check if the deleted schedule was currently active
        let now = Date()
        let wasActive = isCurrentTimeInBlockWindow(
            currentDate: now,
            blockStartHour: deletedSchedule.startHour,
            blockStartMinute: deletedSchedule.startMinute,
            blockEndHour: deletedSchedule.endHour,
            blockEndMinute: deletedSchedule.endMinute
        )

        print("Here 3")
        
        if wasActive {
            print("📱 Deleted schedule was active, checking other schedules...")
            // Check if any other schedule is currently active
            var shouldKeepBlocked = false
            for schedule in model.schedules {
                if schedule.id != deletedSchedule.id && // Skip the deleted schedule
                   isCurrentTimeInBlockWindow(
                    currentDate: now,
                    blockStartHour: schedule.startHour,
                    blockStartMinute: schedule.startMinute,
                    blockEndHour: schedule.endHour,
                    blockEndMinute: schedule.endMinute
                ) {
                    shouldKeepBlocked = true
                    break
                }
            }

            print("Here 4")
            
            if !shouldKeepBlocked {
                print("🔓 No other active schedules, unblocking apps")
                self.unblockAllApps()
            } else {
                print("🔒 Other active schedules found, keeping apps blocked")
            }
        }
    }
    
    func checkAndUnblockForDeletedSchedule(_ deletedSchedule: BlockSchedule) {
        print("🔄 Checking if deleted schedule was active...")
        
        // Check if the deleted schedule was currently active
        let now = Date()
        let wasActive = isCurrentTimeInBlockWindow(
            currentDate: now,
            blockStartHour: deletedSchedule.startHour,
            blockStartMinute: deletedSchedule.startMinute,
            blockEndHour: deletedSchedule.endHour,
            blockEndMinute: deletedSchedule.endMinute
        )
        
        if wasActive {
            print("📱 Deleted schedule was active, checking other schedules...")
            // Check if any other schedule is currently active
            var shouldKeepBlocked = false
            for schedule in model.schedules {
                if isCurrentTimeInBlockWindow(
                    currentDate: now,
                    blockStartHour: schedule.startHour,
                    blockStartMinute: schedule.startMinute,
                    blockEndHour: schedule.endHour,
                    blockEndMinute: schedule.endMinute
                ) {
                    shouldKeepBlocked = true
                    break
                }
            }
            
            if !shouldKeepBlocked {
                print("🔓 No other active schedules, unblocking apps")
                self.unblockAllApps()
            } else {
                print("🔒 Other active schedules found, keeping apps blocked")
            }
        }
    }

    // Method to prepare and show active schedules
    func showActiveSchedules() {
        var schedulesDescription = ""
        for schedule in activeSchedules {
            schedulesDescription += "Schedule ID: \(schedule.id), Start: \(schedule.formattedStartTime()), End: \(schedule.formattedEndTime())\n"
        }
        activeSchedulesText = schedulesDescription
        showActiveSchedulesAlert = true
    }
}
