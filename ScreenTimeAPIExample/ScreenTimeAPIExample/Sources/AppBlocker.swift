import Foundation
import ManagedSettings
import DeviceActivity

struct AppBlocker {
    
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared
    
    // Add properties to represent the start and end times of the blocking window
    var blockStartTimeComponents = DateComponents(hour: 0, minute: 0) // Represents 00:00
    var blockEndTimeComponents = DateComponents(hour: 5, minute: 0) // Represents 05:00

    // Blocking logic with time window
    func block(completion: @escaping (Result<Void, Error>) -> Void) {
        
        // Create a Calendar instance with GMT timezone
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "GMT")!
        
        // Get current date and extract its date components
        let now = Date()
        let currentDateComponents = calendar.dateComponents([.year, .month, .day], from: now)

        // Combine current date components with the blocking time components
        guard let blockStartTime = calendar.date(from: currentDateComponents.settingHour(blockStartTimeComponents.hour!, minute: blockStartTimeComponents.minute!, second: 0)),
              let blockEndTime = calendar.date(from: currentDateComponents.settingHour(blockEndTimeComponents.hour!, minute: blockEndTimeComponents.minute!, second: 0)) else {
            completion(.failure(BlockerError.invalidTimeWindow))
            return
        }
        
        // Print out
        print(now)
        print(blockStartTime)
        print(blockEndTime)

        // Check if the current time falls within the blocking window
        if now >= blockStartTime && now <= blockEndTime {
            // Inside the blocking window, proceed to block apps
            print("Blocking Successful")
            
            // Get selected app tokens
            let selectedAppTokens = model.selectedAppsTokens
            
            // Block activity for all selected app tokens using DeviceActivityCenter
            let deviceActivityCenter = DeviceActivityCenter()
            
            // Set up monitoring DeviceActivitySchedule
            let blockSchedule = DeviceActivitySchedule(
                intervalStart: DateComponents(hour: 0, minute: 0),
                intervalEnd: DateComponents(hour: 23, minute: 59),
                repeats: true
            )
            
            store.shield.applications = selectedAppTokens
            do {
                try deviceActivityCenter.startMonitoring(DeviceActivityName.daily, during: blockSchedule)
                // Trigger tracking of App usage time when monitoring reports an increase in usage time
                // If the time captured is different from the time returned by the API, reassign based on the API time
                // Check if the app is opened and handle push notifications accordingly
                // When the app is closed, remove push scheduling and clear the queue
                // Push policy: exponential decay (adjust to 1 push per minute for less than 1 minute)
                // Capture time from Dynamic Island in milliseconds
                completion(.success(()))
            } catch {
                completion(.failure(error))
                return
            }
        } else {
            // Outside the blocking window, do not block apps
            print("Not in the correct time window, apps not blocked")
            completion(.failure(BlockerError.outsideTimeWindow))
        }
    }

    func unblockAllApps() {
        store.shield.applications = []
    }
    
    // Enum for error handling
    enum BlockerError: Error {
        case invalidTimeWindow
        case outsideTimeWindow
    }
}

// Extension to help combine date components with time components
extension DateComponents {
    func settingHour(_ hour: Int, minute: Int, second: Int) -> DateComponents {
        var copy = self
        copy.hour = hour
        copy.minute = minute
        copy.second = second
        return copy
    }
}
