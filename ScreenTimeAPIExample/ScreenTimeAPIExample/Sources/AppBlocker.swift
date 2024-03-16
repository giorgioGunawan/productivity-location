import Foundation
import ManagedSettings
import DeviceActivity

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

    // Function to start the blocking timer
    func startBlockingTimer(blockStartHour: Int, blockEndHour: Int, blockStartMinute: Int, blockEndMinute: Int) {
        print(blockStartHour)
        print(blockEndHour)
        // Calculate the time interval until the next block schedule
        let currentDate = Date()
        
        print(currentDate)
        let calendar = Calendar.current
        guard let nextBlockDate = calendar.nextDate(after: currentDate, matching: DateComponents(hour: blockStartHour, minute: blockStartMinute), matchingPolicy: .strict) else {
            return
        }
        let timeIntervalUntilBlock = nextBlockDate.timeIntervalSince(currentDate)
        
        self.blockStartHour = blockStartHour;
        self.blockEndHour = blockEndHour;
        self.blockStartMinute = blockStartMinute;
        self.blockEndMinute = blockEndMinute;
        
        var isInTimeRange = isCurrentTimeInBlockWindow(currentDate: currentDate, blockStartHour: blockStartHour, blockStartMinute: blockStartMinute, blockEndHour: blockEndHour, blockEndMinute: blockEndMinute)

        if (isInTimeRange) {
            self.block { result in
                switch result {
                case .success:
                    print("Blocking successful")
                case .failure(let error):
                    print("Blocking failed: \(error.localizedDescription)")
                }
            }
            return;
        }
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
    
    func isCurrentTimeInBlockWindow(currentDate: Date, blockStartHour: Int, blockStartMinute: Int, blockEndHour: Int, blockEndMinute: Int) -> Bool {
        // Get the current calendar and timezone
        let calendar = Calendar.current
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
        let blockEndTime = blockEndHour * 60 + blockEndMinute
        let currentTime = currentHour * 60 + currentMinute
        
        return currentTime >= blockStartTime && currentTime <= blockEndTime
    }
}
