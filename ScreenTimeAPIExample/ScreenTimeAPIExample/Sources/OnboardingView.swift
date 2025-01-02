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
                    WelcomePage(userName: $onboardingModel.userName, onNext: { currentPage = 1 })
                        .tag(0)
                    
                    // Goals Page
                    GoalsPage(selectedGoal: $onboardingModel.selectedGoal, onNext: { currentPage = 2 })
                        .tag(1)
                    
                    // Final Page
                    FinalPage(onboardingModel: onboardingModel)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct WelcomePage: View {
    @Binding var userName: String
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Enhanced icon with animated gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [AppTheme.mainPurple, AppTheme.mainBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    )
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.mainPurple.opacity(0.5), radius: 20)
            
            VStack(spacing: 12) {
                Text("Welcome to")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
                Text("PocketBlock")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 30)
            
            Text("Your digital wellness companion")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.7))
                .padding(.top, 8)
            
            // Enhanced text field
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 40)
                
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.horizontal, 40)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Enhanced button with shadow and animation
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.mainPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

struct GoalsPage: View {
    @Binding var selectedGoal: OnboardingModel.ProductivityGoal
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 25) {
            Text("What's your focus?")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 60)
            
            // Enhanced goal selection cards
            ForEach(OnboardingModel.ProductivityGoal.allCases, id: \.self) { goal in
                Button(action: { 
                    withAnimation(.spring()) {
                        selectedGoal = goal
                    }
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: goalIcon(for: goal))
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(goal.rawValue)
                                .font(.system(size: 18, weight: .semibold))
                            Text(goal.description)
                                .font(.system(size: 14))
                                .opacity(0.8)
                        }
                        
                        Spacer()
                        
                        if selectedGoal == goal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedGoal == goal ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedGoal == goal ? Color.white : Color.clear, lineWidth: 1)
                    )
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button(action: onNext) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.mainPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // Helper function for goal icons
    private func goalIcon(for goal: OnboardingModel.ProductivityGoal) -> String {
        switch goal {
        case .focus: return "brain.head.profile"
        case .social: return "person.2.fill"
        case .gaming: return "gamecontroller.fill"
        case .custom: return "slider.horizontal.3"
        }
    }
}

struct FinalPage: View {
    @ObservedObject var onboardingModel: OnboardingModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Enhanced success animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [AppTheme.mainPurple, AppTheme.mainBlue]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.mainPurple.opacity(0.5), radius: 20)
            
            VStack(spacing: 12) {
                Text("You're all set!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Let's start your focus journey")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    onboardingModel.hasCompletedOnboarding = true
                }
            }) {
                Text("Get Started")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.mainPurple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
}

// Enhanced text field style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
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