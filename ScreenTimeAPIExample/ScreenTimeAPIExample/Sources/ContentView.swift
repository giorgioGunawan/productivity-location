import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingModel: OnboardingModel
    
    var body: some View {
        if !onboardingModel.hasCompletedOnboarding {
            OnboardingView(onboardingModel: onboardingModel)
        } else {
            SwiftUIView()
        }
    }
} 