import UIKit
import FamilyControls
import SwiftUI

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

// MARK: - Onboarding Subviews
struct WelcomePage: View {
    @Binding var userName: String
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to PocketBlock")
                .font(.system(size: 32, weight: .bold))
                .multilineTextAlignment(.center)
            
            TextField("Your name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Text("Swipe to continue →")
                .foregroundColor(.secondary)
        }
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
                    Text(goal.rawValue)
                        .padding()
                }
            }
        }
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

// MARK: - ContentView
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

// MARK: - ViewController
final class ViewController: UIViewController {
    var hostingController: UIHostingController<SwiftUIView>?
    var _center = AuthorizationCenter.shared
    @State private var _appBlocker = AppBlocker()
    private let onboardingModel = OnboardingModel()
    private var debugTapCount = 0
    private var lastTapTime: Date?
    
    private lazy var _contentView: UIHostingController<AnyView> = {
        let model = BlockingApplicationModel.shared
        let contentView = ContentView(onboardingModel: onboardingModel)
            .environmentObject(model)
        return UIHostingController(rootView: AnyView(contentView))
    }()

    private lazy var debugButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.addTarget(self, action: #selector(debugTapped), for: .touchUpInside)
        button.backgroundColor = .clear
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        _setup()
        setupDebugTrigger()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _requestAuthorization()
    }

    private func setupDebugTrigger() {
        view.addSubview(debugButton)
        debugButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            debugButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            debugButton.leftAnchor.constraint(equalTo: view.leftAnchor),
            debugButton.widthAnchor.constraint(equalToConstant: 60),
            debugButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func debugTapped() {
        let currentTime = Date()
        
        if let lastTime = lastTapTime, currentTime.timeIntervalSince(lastTime) > 1.0 {
            debugTapCount = 0
        }
        
        debugTapCount += 1
        lastTapTime = currentTime
        
        if debugTapCount >= 5 {
            debugTapCount = 0
            print("🔍 Debug: Resetting onboarding state")
            onboardingModel.hasCompletedOnboarding = false
            
            // Update the view with new content
            let model = BlockingApplicationModel.shared
            let contentView = ContentView(onboardingModel: onboardingModel)
                .environmentObject(model)
            _contentView.rootView = AnyView(contentView)
        }
    }
}

// MARK: - Setup
extension ViewController {
    private func _setup() {
        _addSubviews()
        _setConstraints()
    }

    private func _addSubviews() {
        addChild(_contentView)
        view.addSubview(_contentView.view)
    }

    private func _setConstraints() {
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
