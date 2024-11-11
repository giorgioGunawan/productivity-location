import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Block apps when schedule starts
        let store = ManagedSettingsStore()
        let model = BlockingApplicationModel.shared
        store.shield.applications = model.selectedAppsTokens
        
        print("🔒 Blocking started at: \(Date())")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Unblock apps when schedule ends
        let store = ManagedSettingsStore()
        store.shield.applications = nil
        
        print("🔓 Blocking ended at: \(Date())")
    }
}
