import SwiftUI

struct OnboardingView: View {
    @ObservedObject var onboardingModel: OnboardingModel
    @State private var currentPage = 0
    
    var body: some View {
        TabView(selection: $currentPage) {
            // Welcome Page
            WelcomePage(userName: $onboardingModel.userName)
                .tag(0)
            
            // Goals Page
            GoalsPage(selectedGoal: $onboardingModel.selectedGoal)
                .tag(1)
            
            // Final Page
            FinalPage(onboardingModel: onboardingModel)
                .tag(2)
        }
        .tabViewStyle(PageTabViewStyle())
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

struct WelcomePage: View {
    @Binding var userName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PocketBlock")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            
            Text("Let's personalize your experience")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
            
            TextField("Your name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 50)
                .padding(.top, 30)
            
            Text("Swipe to continue →")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(.top, 40)
        }
        .padding()
    }
}

struct GoalsPage: View {
    @Binding var selectedGoal: OnboardingModel.ProductivityGoal
    
    var body: some View {
        VStack(spacing: 20) {
            Text("What's your main goal?")
                .font(.system(size: 28, weight: .bold))
            
            ForEach(OnboardingModel.ProductivityGoal.allCases, id: \.self) { goal in
                Button(action: { selectedGoal = goal }) {
                    HStack {
                        Text(goal.rawValue)
                            .foregroundColor(.primary)
                        Spacer()
                        if selectedGoal == goal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color(.systemGray4), radius: 4)
                    )
                }
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FinalPage: View {
    @ObservedObject var onboardingModel: OnboardingModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("You're all set, \(onboardingModel.userName)!")
                .font(.system(size: 28, weight: .bold))
            
            Text("Let's start blocking distractions and boost your productivity.")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                onboardingModel.hasCompletedOnboarding = true
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.mainPurple)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
        }
        .padding()
    }
} 