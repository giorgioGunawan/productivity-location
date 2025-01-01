import SwiftUI

struct ContentView: View {
    @ObservedObject var onboardingModel: OnboardingModel
    @EnvironmentObject var model: BlockingApplicationModel
    
    var body: some View {
        ZStack {
            if !onboardingModel.hasCompletedOnboarding {
                OnboardingView(onboardingModel: onboardingModel)
                    .transition(.opacity)
            } else {
                SwiftUIView()
                    .environmentObject(model)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: onboardingModel.hasCompletedOnboarding)
        .preferredColorScheme(.dark)
    }
} 