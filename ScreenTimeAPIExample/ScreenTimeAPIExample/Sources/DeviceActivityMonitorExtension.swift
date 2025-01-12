import DeviceActivity
import ManagedSettings
import FamilyControls

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        // Block apps when schedule starts
        store.shield.applications = model.selectedAppsTokens
        
        print("🔒 Monitor Extension: Blocking started at: \(Date())")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Unblock apps when schedule ends
        store.shield.applications = []
        
        print("🔓 Monitor Extension: Blocking ended at: \(Date())")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("📊 Monitor Extension: Event reached threshold")
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        print("⚠️ Monitor Extension: Interval will start warning")
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        print("⚠️ Monitor Extension: Interval will end warning")
    }
}