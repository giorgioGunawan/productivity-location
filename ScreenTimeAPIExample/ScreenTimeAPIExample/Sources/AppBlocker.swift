import Foundation
import ManagedSettings
import DeviceActivity

struct AppBlocker {
    
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared
    
    // Blocking logic
    func block(completion: @escaping (Result<Void, Error>) -> Void) {
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
        } catch {
            completion(.failure(error))
            return
        }
        completion(.success(()))
    }
    
    func unblockAllApps() {
        store.shield.applications = []
    }
    
}
