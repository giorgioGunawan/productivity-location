import Foundation
import ManagedSettings
import DeviceActivity
import CoreMotion
import Combine

extension DeviceActivityName {
    static let daily = Self("daily")
}

class AppBlocker: ObservableObject {
    
    let store: ManagedSettingsStore
    let model: BlockingApplicationModel
    var blockStartHour: Int
    var blockStartMinute: Int
    var blockEndHour: Int
    var blockEndMinute: Int
    
    @Published var stepCount: Int = 0 {
        willSet {
            // Debug print to verify the value is being updated
            print("Updating stepCount to: \(newValue)")
        }
    }
    @Published var startedBlocking: Bool = false {
        willSet {
            print("Started blocking: \(newValue)")
        }
    }
    private var pedometer: CMPedometer?
    private var hasReachedGoal: Bool = false
    
    // Add schedule properties
    @Published var isWithinSchedule: Bool = false
    private var scheduleTimer: Timer?
    
    init() {
        self.store = ManagedSettingsStore()
        self.model = BlockingApplicationModel.shared
        self.blockStartHour = 0
        self.blockStartMinute = 0
        self.blockEndHour = 0
        self.blockEndMinute = 0
        self.pedometer = CMPedometer()
    }
    
    // Initialize timer for blocking
    var timer: Timer?
    
    // Function to start the blocking timer
    func startBlockingTimer(blockStartHour: Int, blockEndHour: Int, blockStartMinute: Int, blockEndMinute: Int) {
        // Calculate the time interval until the next block schedule
        let currentDate = Date()
        
        let calendar = Calendar.current
        
        guard let nextBlockDate = calendar.nextDate(after: currentDate,
                                                     matching: DateComponents(hour: blockStartHour, minute: blockStartMinute),
                                                     matchingPolicy: .strict),
              let nextBlockEndDate = calendar.nextDate(after: currentDate,
                                                        matching: DateComponents(hour: blockEndHour, minute: blockEndMinute),
                                                        matchingPolicy: .strict)
        else {
            return
        }
        
        let timeIntervalUntilBlock = nextBlockDate.timeIntervalSince(currentDate)
        let timeIntervalUntilUnblock = nextBlockEndDate.timeIntervalSince(currentDate)
        
        self.blockStartHour = blockStartHour;
        self.blockEndHour = blockEndHour;
        self.blockStartMinute = blockStartMinute;
        self.blockEndMinute = blockEndMinute;

        configureMonitorExtension()
        
        let isInTimeRange = isCurrentTimeInBlockWindow(currentDate: currentDate, blockStartHour: blockStartHour, blockStartMinute: blockStartMinute, blockEndHour: blockEndHour, blockEndMinute: blockEndMinute)

        if (isInTimeRange) {
            self.block(completion: { _ in})
        } else {
            scheduleBlockTimer(after: timeIntervalUntilBlock);
        }

        self.startedBlocking = true
    
        // If current time is exactly the same as the schedule unblock end, schedule unblock for one minute extra
        if isCurrentTimeEqualToDateUpToMinute(currentDate, nextBlockEndDate) {
            // Dates are equal up to the minute
            scheduleUnblockTimer(after: timeIntervalUntilUnblock + 60) // Adding one minute to the time interval
        } else {
            // Dates are not equal up to the minute
            scheduleUnblockTimer(after: timeIntervalUntilUnblock)
        }
    }
    
    func startBlockingSchedule(schedule: BlockSchedule) {
        print("🔄 Starting blocking for schedule: \(schedule.formattedStartTime()) - \(schedule.formattedEndTime())")
        
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
            try deviceActivityCenter.startMonitoring(.daily, during: deviceSchedule)
            
            // If we're currently within the schedule, block immediately
            if isCurrentTimeInBlockWindow(currentDate: Date(),
                                        blockStartHour: schedule.startHour,
                                        blockStartMinute: schedule.startMinute,
                                        blockEndHour: schedule.endHour,
                                        blockEndMinute: schedule.endMinute) {
                print("📱 Currently within schedule window - blocking apps")
                store.shield.applications = model.selectedAppsTokens
            } else {
                print("⏳ Outside schedule window - waiting for start time")
            }
            
            self.startedBlocking = true
            print("✅ Monitoring started successfully")
        } catch {
            print("❌ Failed to start monitoring: \(error)")
        }
    }
    
    // Add this function to enforce all active schedules
    func enforceActiveSchedules() {
        let now = Date()
        var shouldBlock = false
        
        // Check if current time falls within any active schedule
        for schedule in model.schedules where schedule.isActive {
            if isCurrentTimeInBlockWindow(
                currentDate: now,
                blockStartHour: schedule.startHour,
                blockStartMinute: schedule.startMinute,
                blockEndHour: schedule.endHour,
                blockEndMinute: schedule.endMinute
            ) {
                shouldBlock = true
                break
            }
        }
        
        if shouldBlock {
            store.shield.applications = model.selectedAppsTokens
            startedBlocking = true
        } else {
            store.shield.applications = []
            startedBlocking = false
        }
    }

    // Blocking logic with time window
    public func block(completion: @escaping (Result<Void, Error>) -> Void) {
        print("🔒 Blocking apps...")
        // Get selected app tokens
        let selectedAppTokens = model.selectedAppsTokens
        
        // Block activity for all selected app tokens using DeviceActivityCenter
        let deviceActivityCenter = DeviceActivityCenter()
        
        // Set up monitoring DeviceActivitySchedule
        let blockSchedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: self.blockStartHour, minute: self.blockStartMinute),
            intervalEnd: DateComponents(hour: self.blockEndHour, minute: self.blockEndMinute),
            repeats: false
        )
        
        store.shield.applications = selectedAppTokens

        configureMonitorExtension()

        do {
            try deviceActivityCenter.startMonitoring(DeviceActivityName.daily, during: blockSchedule)
            completion(.success(()))
        } catch {
            completion(.failure(error))
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
    
    private func scheduleBlockTimer(after timeInterval: TimeInterval) {
        Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.block(completion: { _ in})
        }
    }

    // Function to unblock all apps
    func unblockAllApps() {
        store.shield.applications = []
        self.startedBlocking = false
        stopMonitoring()
    }

    func configureMonitorExtension() {
        let deviceActivityCenter = DeviceActivityCenter()
        
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: blockStartHour, minute: blockStartMinute),
            intervalEnd: DateComponents(hour: blockEndHour, minute: blockEndMinute),
            repeats: true
        )
        
        do {
            try deviceActivityCenter.startMonitoring(.daily, during: schedule)
            print("🔄 Monitor extension configured for: \(blockStartHour):\(blockStartMinute) to \(blockEndHour):\(blockEndMinute)")
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
                            self.unblockApplicationsTemporarily()
                        }
                    }
                }
            })
        }
    }
    
    func startStepCounting() {
        if CMPedometer.isStepCountingAvailable() {
            let pedometer = CMPedometer()
            pedometer.startUpdates(from: Date()) { pedometerData, error in
                DispatchQueue.main.async { // Ensure updates are handled on the main thread
                    guard let data = pedometerData, error == nil else {
                        print("Error starting step counting: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    let steps = data.numberOfSteps.intValue
                    print("Number of steps: \(steps)")
                    print("Start")
                    // Check if the user has walked 10 steps
                    if steps >= 15 {
                        // Unblock the applications
                        self.unblockApplicationsTemporarily()
                        // Stop step counting
                        pedometer.stopUpdates()
                        
                        return
                    }
                    // Publish the step count on the main thread
                    self.stepCount = steps
                }
            }
        } else {
            print("Step counting not available on this device.")
        }
    }
    
    func unblockApplicationsTemporarily() {
        store.shield.applications = []
        // Schedule reblock after 5 minutes
        scheduleBlockTimer(after: 300)
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
    
    /*
    func isCurrentTimeInBlockWindow(currentDate: Date, blockStartHour: Int, blockStartMinute: Int, blockEndHour: Int, blockEndMinute: Int) -> Bool {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: currentDate)
        guard let currentHour = components.hour, let currentMinute = components.minute else {
            return false
        }
        
        let currentTime = currentHour * 60 + currentMinute
        let startTime = blockStartHour * 60 + blockStartMinute
        let endTime = blockEndHour * 60 + blockEndMinute
        
        // Handle overnight schedules (e.g., 23:00 to 06:00)
        if endTime < startTime {
            return currentTime >= startTime || currentTime <= endTime
        } else {
            return currentTime >= startTime && currentTime <= endTime
        }
    }*/
    
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

    // New function to start schedule
    func startBlockingSchedule(scheduleStartHour: Int, scheduleStartMinute: Int, 
                             scheduleEndHour: Int, scheduleEndMinute: Int) {
        print("🔄 Starting blocking schedule...")
        
        // Get selected app tokens
        let selectedAppTokens = model.selectedAppsTokens
        print("📱 Selected apps: \(selectedAppTokens)")
        
        // Set up DeviceActivityCenter
        let deviceActivityCenter = DeviceActivityCenter()
        
        // Create the schedule components
        var startComponents = DateComponents()
        startComponents.hour = scheduleStartHour
        startComponents.minute = scheduleStartMinute
        
        var endComponents = DateComponents()
        endComponents.hour = scheduleEndHour
        endComponents.minute = scheduleEndMinute
        
        print("⏰ Schedule set for: \(scheduleStartHour):\(scheduleStartMinute) to \(scheduleEndHour):\(scheduleEndMinute)")
        
        // Check if we're currently within the schedule
        let calendar = Calendar.current
        let now = Date()
        let currentComponents = calendar.dateComponents([.hour, .minute], from: now)
        let currentTime = currentComponents.hour! * 60 + currentComponents.minute!
        let startTime = scheduleStartHour * 60 + scheduleStartMinute
        let endTime = scheduleEndHour * 60 + scheduleEndMinute
        print("🕐 Current time: \(currentComponents.hour!):\(currentComponents.minute!)")

        let schedule = DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: true
        )
        
        do {
            try deviceActivityCenter.startMonitoring(.daily, during: schedule)
            print("✅ Monitoring started successfully")
            
            // If we're currently within the schedule, block immediately
            if isCurrentTimeInBlockWindow(currentDate: now,
                                        blockStartHour: scheduleStartHour,
                                        blockStartMinute: scheduleStartMinute,
                                        blockEndHour: scheduleEndHour,
                                        blockEndMinute: scheduleEndMinute) {
                print("📱 Currently within block window - blocking apps immediately")
                store.shield.applications = selectedAppTokens
            } else {
                print("⏳ Outside block window - waiting for scheduled time")
            }
            
            self.startedBlocking = true
            print("Schedule started: \(scheduleStartHour):\(scheduleStartMinute) to \(scheduleEndHour):\(scheduleEndMinute)")
        } catch {
            print("Failed to start monitoring: \(error)")
        }
    }

    // Add cleanup for schedule
    func stopSchedule() {
        let deviceActivityCenter = DeviceActivityCenter()
        deviceActivityCenter.stopMonitoring([.daily])
        unblockAllApps()
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
                store.shield.applications = []
                startedBlocking = false
            } else {
                print("🔒 Other active schedules found, keeping apps blocked")
            }
        }
    }
}
