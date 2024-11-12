import Foundation
import FamilyControls
import ManagedSettings

final class BlockingApplicationModel: ObservableObject {
    static let shared = BlockingApplicationModel()
    
    @Published var newSelection: FamilyActivitySelection = .init() {
        didSet {
            print("🔄 Selection changed!")
            print("New tokens: \(newSelection.applicationTokens)")
            saveSelectedAppTokens()
        }
    }
    private let appGroupIdentifier = "group.com.productivityone.productivityApp" // Change this to match your app group ID
    
    // Computed property to convert FamilyActivitySelection to a set of ApplicationToken
    var selectedAppsTokens: Set<ApplicationToken> {
        newSelection.applicationTokens
    }
    
    private let selectedAppsKey = "SelectedAppsTokens"
    
    private init() {
        loadSelectedAppTokens()
    }
    
    // Function to save the selected app tokens to UserDefaults
    private func saveSelectedAppTokens() {
        print("⭐️ Starting saveSelectedAppTokens...")
        guard let groupUserDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
        
        do {
            let tokens = newSelection.applicationTokens
            print("📱 Tokens to save: \(tokens)")
            let encodedData = try JSONEncoder().encode(tokens)
            groupUserDefaults.set(encodedData, forKey: "SelectedAppsTokens")
            groupUserDefaults.synchronize()
            print("✅ Successfully saved tokens to shared storage")
            
            // Verify save
            if let savedData = groupUserDefaults.data(forKey: "SelectedAppsTokens") {
                print("✅ Verified data exists in UserDefaults")
                print("Data size: \(savedData.count) bytes")
            } else {
                print("❌ WARNING: Data not found in UserDefaults after save")
            }
        } catch {
            print("❌ Failed to encode tokens: \(error)")
        }
    }
    
    // Function to load the selected app tokens from UserDefaults
    private func loadSelectedAppTokens() {
        guard let groupUserDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }
                
        if let encodedData = UserDefaults.standard.data(forKey: selectedAppsKey),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: encodedData) {
            newSelection.applicationTokens = tokens // Assign directly to newSelection.applicationTokens
            print("📱 Loaded tokens from shared storage: \(tokens)")
        }
    }
}
