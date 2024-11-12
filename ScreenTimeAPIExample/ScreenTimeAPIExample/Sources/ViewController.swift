import UIKit
import FamilyControls
import SwiftUI

final class ViewController: UIViewController {

    var hostingController: UIHostingController<SwiftUIView>?
    
    var _center = AuthorizationCenter.shared

    @State private var _appBlocker = AppBlocker()

    private lazy var _contentView: UIHostingController<some View> = {
        let model = BlockingApplicationModel.shared
        // Calls the SwiftUIView class - and I think that's it?
        let hostingController = UIHostingController(
            rootView: SwiftUIView()
                .environmentObject(model)
        )
        return hostingController
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        _setup()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _requestAuthorization()
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
