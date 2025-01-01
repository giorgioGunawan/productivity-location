import Foundation
import FamilyControls
import ManagedSettings

final class BlockingApplicationModel: ObservableObject {
    static let shared = BlockingApplicationModel()
    static let appGroupID = "group.com.productivityone.productivityApp"
    
    @Published var newSelection: FamilyActivitySelection = .init() {
        didSet {
            saveSelectedAppTokens()
        }
    }
    
    @Published var schedules: [BlockSchedule] = [] {
        didSet {
            saveSchedules()
        }
    }
    
    // Computed property for app tokens
    var selectedAppsTokens: Set<ApplicationToken> {
        newSelection.applicationTokens
    }
    
    private let selectedAppsKey = "SelectedAppsTokens"
    private let schedulesKey = "SavedSchedules"
    
    private init() {
        loadSelectedAppTokens()
        loadSchedules()
    }
    
    // App tokens persistence
    private func saveSelectedAppTokens() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        do {
            let encodedData = try JSONEncoder().encode(selectedAppsTokens)
            groupUserDefaults.set(encodedData, forKey: selectedAppsKey)
            groupUserDefaults.synchronize()
            print("✅ Saved tokens to shared storage: \(selectedAppsTokens)")
        } catch {
            print("❌ Failed to encode tokens: \(error)")
        }
    }
    
    private func loadSelectedAppTokens() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        if let encodedData = groupUserDefaults.data(forKey: selectedAppsKey),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: encodedData) {
            newSelection.applicationTokens = tokens
            print("✅ Loaded tokens from shared storage: \(tokens)")
        }
    }
    
    // Schedules persistence
    private func saveSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        if let encoded = try? JSONEncoder().encode(schedules) {
            groupUserDefaults.set(encoded, forKey: schedulesKey)
            groupUserDefaults.synchronize()
            print("✅ Saved schedules: \(schedules)")
        }
    }
    
    private func loadSchedules() {
        guard let groupUserDefaults = UserDefaults(suiteName: Self.appGroupID) else { return }
        if let data = groupUserDefaults.data(forKey: schedulesKey),
           let decoded = try? JSONDecoder().decode([BlockSchedule].self, from: data) {
            schedules = decoded
            print("✅ Loaded schedules: \(decoded)")
        }
    }
}
