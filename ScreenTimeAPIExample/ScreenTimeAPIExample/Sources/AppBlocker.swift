import Foundation
import ManagedSettings
import DeviceActivity
import CoreMotion
import Combine

class AppBlocker: ObservableObject {
    
    let store: ManagedSettingsStore
    let model: BlockingApplicationModel
    var blockStartHour: Int
    var blockStartMinute: Int
    var blockEndHour: Int
    var blockEndMinute: Int
    
    init() {
        self.store = ManagedSettingsStore()
        self.model = BlockingApplicationModel.shared
        self.blockStartHour = 0
        self.blockStartMinute = 0
        self.blockEndHour = 0
        self.blockEndMinute = 0
    }
    
    // Initialize timer for blocking
    var timer: Timer?
    
    @Published var stepCount: Int = 0

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
        
        let isInTimeRange = isCurrentTimeInBlockWindow(currentDate: currentDate, blockStartHour: blockStartHour, blockStartMinute: blockStartMinute, blockEndHour: blockEndHour, blockEndMinute: blockEndMinute)

        if (isInTimeRange) {
            self.block(completion: { _ in})
        } else {
            scheduleBlockTimer(after: timeIntervalUntilBlock);
        }
    
        // If current time is exactly the same as the schedule unblock end, schedule unblock for one minute extra
        if isCurrentTimeEqualToDateUpToMinute(currentDate, nextBlockEndDate) {
            // Dates are equal up to the minute
            scheduleUnblockTimer(after: timeIntervalUntilUnblock + 60) // Adding one minute to the time interval
        } else {
            // Dates are not equal up to the minute
            scheduleUnblockTimer(after: timeIntervalUntilUnblock)
        }
    }

    // Blocking logic with time window
    public func block(completion: @escaping (Result<Void, Error>) -> Void) {
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
        do {
            try deviceActivityCenter.startMonitoring(DeviceActivityName.daily, during: blockSchedule)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
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
    }
    
    func unblockTemp() {
        startStepCounting()
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
        // Unblock after 5 minutes
        scheduleBlockTimer(after: 300)
        self.stepCount = 0
    }
    
    // Enum for error handling
    enum BlockerError: Error {
        case invalidTimeWindow
        case outsideTimeWindow
        case invalidTimeZone
    }
    
    func isCurrentTimeInBlockWindow(currentDate: Date, blockStartHour: Int, blockStartMinute: Int, blockEndHour: Int, blockEndMinute: Int) -> Bool {
        // Get the current calendar and timezone
        _ = Calendar.current
        let userTimeZone = TimeZone.current
        
        // Set the calendar's timezone
        var calendarWithTimeZone = Calendar.current
        calendarWithTimeZone.timeZone = userTimeZone
        
        // Get the hour and minute components from the current date
        let components = calendarWithTimeZone.dateComponents([.hour, .minute], from: currentDate)
        guard let currentHour = components.hour, let currentMinute = components.minute else {
            return false
        }
        
        // Check if the current time falls within the block window
        let blockStartTime = blockStartHour * 60 + blockStartMinute
        
        // Block end time minus one minute so you CANNOT block on the same minute
        // This is because it'll lead to edge cases
        let blockEndTime = blockEndHour * 60 + blockEndMinute - 1
        let currentTime = currentHour * 60 + currentMinute
            
        return currentTime >= blockStartTime && currentTime <= blockEndTime
    }
    
    func isCurrentTimeEqualToDateUpToMinute(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.hour, .minute], from: date1)
        let components2 = calendar.dateComponents([.hour, .minute], from: date2)
        return components1 == components2
    }
}
