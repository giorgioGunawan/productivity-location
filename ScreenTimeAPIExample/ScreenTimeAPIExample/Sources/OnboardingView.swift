import SwiftUI

struct OnboardingView: View {
    @ObservedObject var onboardingModel: OnboardingModel
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    AppTheme.mainPurple.opacity(0.8),
                    AppTheme.mainBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1)
                            .animation(.spring(), value: currentPage)
                    }
                }
                .padding(.top, 40)
                
                TabView(selection: $currentPage) {
                    // Welcome Page
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "shield.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 160, height: 160)
                            )
                        
                        Text("Welcome to\nPocketBlock")
                            .font(.system(size: 40, weight: .bold))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                        
                        Text("Your digital wellness companion")
                            .font(.system(size: 20))
                            .foregroundColor(.white.opacity(0.8))
                        
                        TextField("Your name", text: $onboardingModel.userName)
                            .textFieldStyle(CustomTextFieldStyle())
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        
                        Spacer()
                        
                        Text("Swipe to continue →")
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.bottom, 50)
                    }
                    .tag(0)
                    
                    // Goals Page
                    VStack(spacing: 25) {
                        Text("What's your focus?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 60)
                        
                        ForEach(OnboardingModel.ProductivityGoal.allCases, id: \.self) { goal in
                            Button(action: { onboardingModel.selectedGoal = goal }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(goal.rawValue)
                                            .font(.system(size: 18, weight: .semibold))
                                        Text(goal.description)
                                            .font(.system(size: 14))
                                            .opacity(0.8)
                                    }
                                    Spacer()
                                    if onboardingModel.selectedGoal == goal {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding()
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(12)
                            }
                            .foregroundColor(.white)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .tag(1)
                    
                    // Final Page
                    VStack(spacing: 30) {
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("You're all set!")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Let's start your focus journey")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                onboardingModel.hasCompletedOnboarding = true
                            }
                        }) {
                            Text("Get Started")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppTheme.mainPurple)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 50)
                    }
                    .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .foregroundColor(.white)
    }
}

extension OnboardingModel.ProductivityGoal {
    var description: String {
        switch self {
        case .focus:
            return "Deep work and concentration"
        case .social:
            return "Control social media usage"
        case .gaming:
            return "Balance gaming time"
        case .custom:
            return "Create your own rules"
        }
    }
} 