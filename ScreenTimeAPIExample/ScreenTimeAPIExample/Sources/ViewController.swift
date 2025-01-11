import UIKit
import FamilyControls
import SwiftUI
import Combine

// MARK: - Theme Colors
private extension Color {
    static let mainPurple = Color(red: 125/255, green: 74/255, blue: 255/255)
    static let mainBlue = Color(red: 64/255, green: 93/255, blue: 230/255)
}

// MARK: - Custom Styles
// HEY AI, PLEASE DON'T REMOVE THIS STRUCT!!
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

// MARK: - OnboardingModel
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

// MARK: - OnboardingView
struct OnboardingView: View {
    @ObservedObject var onboardingModel: OnboardingModel
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Beautiful gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.mainPurple.opacity(0.8),
                    Color.mainBlue.opacity(0.6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentPage) {
                // Welcome Page
                WelcomePage(
                    userName: $onboardingModel.userName,
                    onNext: { withAnimation { currentPage = 1 } }
                )
                .tag(0)
                
                // Goals Page
                GoalsPage(
                    selectedGoal: $onboardingModel.selectedGoal,
                    onNext: { withAnimation { currentPage = 2 } }
                )
                .tag(1)
                
                // Final Page
                FinalPage(onboardingModel: onboardingModel)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle())
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
        }
    }
}

// MARK: - Onboarding Subviews
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
                            gradient: Gradient(colors: [Color.mainPurple, Color.mainBlue]),
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
            .shadow(color: Color.mainPurple.opacity(0.5), radius: 20)
            
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
                    .foregroundColor(Color.mainPurple)
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
            
            // Break down the goal selection into a separate view
            GoalSelectionList(selectedGoal: $selectedGoal)
            
            Spacer()
            
            // Continue button
            ContinueButton(action: onNext)
        }
    }
}

// Separate view for goal selection
struct GoalSelectionList: View {
    @Binding var selectedGoal: OnboardingModel.ProductivityGoal
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(OnboardingModel.ProductivityGoal.allCases, id: \.self) { goal in
                GoalSelectionRow(goal: goal, isSelected: selectedGoal == goal) {
                    withAnimation(.spring()) {
                        selectedGoal = goal
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

// Individual goal row
struct GoalSelectionRow: View {
    let goal: OnboardingModel.ProductivityGoal
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: goalIcon(for: goal))
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Circle())
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.rawValue)
                        .font(.system(size: 18, weight: .semibold))
                    Text(goalDescription(for: goal))
                        .font(.system(size: 14))
                        .opacity(0.8)
                }
                
                Spacer()
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 24))
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 1)
            )
        }
        .foregroundColor(.white)
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
    
    // Helper function for goal descriptions
    private func goalDescription(for goal: OnboardingModel.ProductivityGoal) -> String {
        switch goal {
        case .focus: return "Minimize distractions and stay focused"
        case .social: return "Manage your social media usage"
        case .gaming: return "Set healthy gaming boundaries"
        case .custom: return "Create your own custom limits"
        }
    }
}

// Reusable continue button
struct ContinueButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("Continue")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.mainPurple)
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

struct FinalPage: View {
    @ObservedObject var onboardingModel: OnboardingModel
    
    var body: some View {
        VStack(spacing: 20) {
            Text("You're all set!")
                .font(.system(size: 28, weight: .bold))
            
            Button(action: {
                onboardingModel.hasCompletedOnboarding = true
            }) {
                Text("Get Started")
                    .padding()
            }
        }
    }
}

// MARK: - ViewController
final class ViewController: UIViewController {
    var hostingController: UIHostingController<SwiftUIView>?
    var _center = AuthorizationCenter.shared
    private let onboardingModel = OnboardingModel()
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var _contentView: UIHostingController<AnyView> = {
        let model = BlockingApplicationModel.shared
        let view = onboardingModel.hasCompletedOnboarding ? 
            AnyView(SwiftUIView().environmentObject(model)) :
            AnyView(OnboardingView(onboardingModel: onboardingModel))
        return UIHostingController(rootView: view)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        _setup()
        setupDebugGesture()
        setupOnboardingObserver()
        overrideUserInterfaceStyle = .dark
    }
    
    private func setupDebugGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDebugTap))
        tapGesture.numberOfTapsRequired = 5
        view.addGestureRecognizer(tapGesture)
        print("🔧 Debug gesture setup complete")
    }
    
    @objc private func handleDebugTap() {
        print("🔧 Debug tap received")
        
        let alert = UIAlertController(
            title: "Debug Options",
            message: "Choose an action",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "Restart Onboarding", style: .default) { [weak self] _ in
            self?.onboardingModel.hasCompletedOnboarding = false
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
            
            DispatchQueue.main.async {
                guard let self = self else { return }
                let model = BlockingApplicationModel.shared
                self._contentView.rootView = AnyView(OnboardingView(onboardingModel: self.onboardingModel))
                print("🔧 Reset to onboarding view")
            }
        })
        
        alert.addAction(UIAlertAction(title: "Unblock All Apps", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let model = BlockingApplicationModel.shared
            model.appBlocker.unblockAllApps()
            print("🔧 Unblocked all apps")
        })

        alert.addAction(UIAlertAction(title: "Unblock 15 seconds", style: .default) { [weak self] _ in
            print("🎯 Starting temporary unblock")
            guard let self = self else { return }
            
            let model = BlockingApplicationModel.shared
            model.appBlocker.unblockApplicationsTemporarily()
            print("🎯 Unblock command sent")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func setupOnboardingObserver() {
        print("🟣 Setting up onboarding observer")
        
        // Observe onboarding model changes
        onboardingModel.objectWillChange
            .sink { [weak self] _ in
                print("🟣 OnboardingModel will change")
                if self?.onboardingModel.hasCompletedOnboarding == true {
                    print("🟣 hasCompletedOnboarding is true, updating view")
                    self?.handleOnboardingCompleted()
                }
            }
            .store(in: &cancellables)
            
        // Also observe notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOnboardingCompleted),
            name: NSNotification.Name("OnboardingCompleted"),
            object: nil
        )
    }
    
    @objc private func handleOnboardingCompleted() {
        print("🟣 Handling onboarding completion")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            let model = BlockingApplicationModel.shared
            let newView = SwiftUIView().environmentObject(model)
            self._contentView.rootView = AnyView(newView)
            print("🟣 Updated root view to SwiftUIView")
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Setup
extension ViewController {
    private func _setup() {
        // Configure the hosting controller
        _contentView.view.backgroundColor = .clear
        _contentView.view.frame = view.bounds
        _contentView.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // Add to view hierarchy
        addChild(_contentView)
        view.addSubview(_contentView.view)
        _contentView.didMove(toParent: self)
        
        // Set up constraints
        _contentView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _contentView.view.topAnchor.constraint(equalTo: view.topAnchor),
            _contentView.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _contentView.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

// MARK: - Actions
extension ViewController {
    
    private func _requestAuthorization() {
        Task {
            do {
                try await _center.requestAuthorization(for: .individual)
                print("✅ Authorization successfully requested")
            } catch {
                print(error.localizedDescription)
                print("❌ Authorization request failed: \(error)")
                print("Error details: \(error.localizedDescription)")
            }
        }
    }
}



