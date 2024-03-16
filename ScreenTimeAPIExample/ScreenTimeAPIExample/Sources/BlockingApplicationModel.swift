import Foundation
import FamilyControls
import ManagedSettings

final class BlockingApplicationModel: ObservableObject {
    static let shared = BlockingApplicationModel()
    
    @Published var newSelection: FamilyActivitySelection = .init() {
        didSet {
            saveSelectedAppTokens()
        }
    }
    
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
        let encodedData = try? JSONEncoder().encode(selectedAppsTokens)
        UserDefaults.standard.set(encodedData, forKey: selectedAppsKey)
    }
    
    // Function to load the selected app tokens from UserDefaults
    private func loadSelectedAppTokens() {
        if let encodedData = UserDefaults.standard.data(forKey: selectedAppsKey),
           let tokens = try? JSONDecoder().decode(Set<ApplicationToken>.self, from: encodedData) {
            newSelection.applicationTokens = tokens // Assign directly to newSelection.applicationTokens
        }
    }
}
