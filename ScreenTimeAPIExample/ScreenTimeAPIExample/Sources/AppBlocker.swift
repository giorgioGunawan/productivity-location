import Foundation
import ManagedSettings
import DeviceActivity

struct AppBlocker {
    
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared
    
    // Add properties to represent the start and end times of the blocking window
    var blockStartTimeComponents = DateComponents(hour: 0, minute: 0) // Represents 00:00
    var blockEndTimeComponents = DateComponents(hour: 9, minute: 0) // Represents 09:00

    // Blocking logic with time window
    func block(completion: @escaping (Result<Void, Error>) -> Void) {
        
        // Get user's current timezone
        let userTimeZone = TimeZone.current
        
        // Create a Calendar instance with user's timezone
        var calendar = Calendar.current
        calendar.timeZone = userTimeZone
                
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        let timeNow = dateFormatter.string(from: Date())
        
        // ===== Convert block times
        calendar.timeZone = TimeZone(identifier: "GMT")!
        
        // Combine the current date with the block start time components to get the block start time
        let blockStartTime = calendar.date(bySettingHour: blockStartTimeComponents.hour!, minute: blockStartTimeComponents.minute!, second: 0, of: Date());
        let blockEndTime = calendar.date(bySettingHour: blockEndTimeComponents.hour!, minute: blockEndTimeComponents.minute!, second: 0, of: Date());
        
        let blockStart = dateFormatter.string(from: blockStartTime!)
        let blockEnd = dateFormatter.string(from: blockEndTime!)
        
        let shouldBlock = isTimeInRange(timeNow: timeNow, blockStart: blockStart, blockEnd: blockEnd);
        
        // Check if the current time falls within the blocking window
        if shouldBlock {
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
    
    func isTimeInRange(timeNow: String, blockStart: String, blockEnd: String) -> Bool {
        // Create date formatter for parsing time strings
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        
        // Parse time strings to Date objects
        guard let timeNowDate = dateFormatter.date(from: timeNow),
              let blockStartDate = dateFormatter.date(from: blockStart),
              let blockEndDate = dateFormatter.date(from: blockEnd) else {
            // Unable to parse time strings, return false
            return false
        }
        
        // Check if timeNow is within blockStart and blockEnd
        return timeNowDate >= blockStartDate && timeNowDate <= blockEndDate
    }
    
    // Enum for error handling
    enum BlockerError: Error {
        case invalidTimeWindow
        case outsideTimeWindow
        case invalidTimeZone
    }
}

extension Date {
    func inTimeZone(_ timeZone: TimeZone) -> Date {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dateString = formatter.string(from: self)
        return formatter.date(from: dateString)!
    }
}
