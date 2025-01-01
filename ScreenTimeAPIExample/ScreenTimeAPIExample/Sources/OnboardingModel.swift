import SwiftUI

class OnboardingModel: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }
    @Published var userName: String = ""
    @Published var selectedGoal: ProductivityGoal = .focus
    
    enum ProductivityGoal: String, CaseIterable {
        case focus = "Deep Focus"
        case social = "Social Media Balance"
        case gaming = "Gaming Control"
        case custom = "Custom Goals"
    }
    
    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
} 