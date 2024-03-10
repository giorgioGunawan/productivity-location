import Foundation
import ManagedSettings
import DeviceActivity

struct AppBlocker {
    
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared

    // Define the start and end times for the blocking window
    let blockStartHour = 00 // 02:00 AM
    let blockStartMinute = 28
    let blockEndHour = 1 // 02:50 AM
    let blockEndMinute = 50

    // Initialize timer for blocking
    var timer: Timer?

    // Function to start the blocking timer
    mutating func startBlockingTimer() {
        // Calculate the time interval until the next block schedule
        let currentDate = Date()
        let calendar = Calendar.current
        guard let nextBlockDate = calendar.nextDate(after: currentDate, matching: DateComponents(hour: blockStartHour, minute: blockStartMinute), matchingPolicy: .strict) else {
            return
        }
        let timeIntervalUntilBlock = nextBlockDate.timeIntervalSince(currentDate)

        // Schedule the timer to start blocking at the next block schedule time
        timer = Timer.scheduledTimer(withTimeInterval: timeIntervalUntilBlock, repeats: false) { [self] timer in
            self.block { result in
                // Handle completion of block operation if needed
            }
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
            intervalStart: DateComponents(hour: blockStartHour, minute: blockStartMinute),
            intervalEnd: DateComponents(hour: blockEndHour, minute: blockEndMinute),
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

    // Function to unblock all apps
    func unblockAllApps() {
        store.shield.applications = []
    }
    
    // Enum for error handling
    enum BlockerError: Error {
        case invalidTimeWindow
        case outsideTimeWindow
        case invalidTimeZone
    }
}
