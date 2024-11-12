import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    let model = BlockingApplicationModel.shared
    let appGroupIdentifier = "group.com.productivityone.productivityApp" // Same as above
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        
        let tokens = loadSelectedAppTokens()
        print("🔒 Monitor Extension: Starting block with tokens: \(tokens)")
        store.shield.applications = tokens
        
        // Block apps when schedule starts
        // store.shield.applications = model.selectedAppsTokens
        
        // Verify the shield was applied
        if let shieldedApps = store.shield.applications {
            print("✅ Shield applied successfully to \(shieldedApps.count) apps")
        } else {
            print("❌ Failed to apply shield")
        }
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        
        // Unblock apps when schedule ends
        store.shield.applications = nil
        
        print("🔓 Monitor Extension: Blocking ended at: \(Date())")
    }
    
    private func loadSelectedAppTokens() -> Set<ApplicationToken> {
        guard let groupUserDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Monitor Extension: Failed to access App Group UserDefaults")
            return []
        }
        
        guard let encodedData = groupUserDefaults.data(forKey: "SelectedAppsTokens") else {
            print("❌ No data found for key 'SelectedAppsTokens'")
            // List all available keys
            print("Available keys in UserDefaults: \(groupUserDefaults.dictionaryRepresentation().keys)")
            return []
        }
                
        do {
            let tokens = try JSONDecoder().decode(Set<ApplicationToken>.self, from: encodedData)
            print("✅ Successfully decoded tokens: \(tokens)")
            return tokens
        } catch {
            print("❌ Failed to decode tokens: \(error)")
            return []
        }
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
