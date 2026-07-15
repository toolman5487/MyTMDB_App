//
//  BaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SnapKit
import UIKit

// MARK: - BaseViewController

@MainActor
class BaseViewController: UIViewController {

    // MARK: - Properties

    private var keyboardDismissTapGesture: UITapGestureRecognizer?

    private lazy var baseLoadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.background.withAlphaComponent(0.4)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    private lazy var baseLoadingView = {
        AppFactory.Animation.popcornLoading(
            size: AppAnimationView.Metrics.overlaySize,
            startsAnimating: false
        )
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.background
        configureView()
        setupHierarchy()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Template Methods

    func configureView() {}

    func setupHierarchy() {}

    func setupConstraints() {}

    func bindViewModel() {}

    // MARK: - Loading

    func setLoadingVisible(_ isVisible: Bool, animated: Bool = true) {
        ensureLoadingOverlayIfNeeded()

        let updates = {
            self.baseLoadingOverlayView.alpha = isVisible ? 1 : 0
        }

        switch (isVisible, animated) {
        case (true, true):
            baseLoadingOverlayView.isHidden = false
            baseLoadingView.setAnimating(true)
            UIView.animate(withDuration: 0.2, animations: updates)

        case (true, false):
            baseLoadingOverlayView.isHidden = false
            baseLoadingView.setAnimating(true)
            updates()

        case (false, true):
            UIView.animate(withDuration: 0.2, animations: updates) { [weak self] _ in
                self?.baseLoadingOverlayView.isHidden = true
                self?.baseLoadingView.setAnimating(false)
            }

        case (false, false):
            updates()
            baseLoadingOverlayView.isHidden = true
            baseLoadingView.setAnimating(false)
        }
    }

    // MARK: - Alert

    func presentAlert(title: String, message: String, actionTitle: String = "OK") {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: actionTitle, style: .default))
        present(alert, animated: true)
    }

    // MARK: - Keyboard

    func enableKeyboardDismissOnTap(cancelsTouchesInView: Bool = false) {
        guard keyboardDismissTapGesture == nil else { return }
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleKeyboardDismissTap))
        gesture.cancelsTouchesInView = cancelsTouchesInView
        view.addGestureRecognizer(gesture)
        keyboardDismissTapGesture = gesture
    }

    func disableKeyboardDismissOnTap() {
        guard let keyboardDismissTapGesture else { return }
        view.removeGestureRecognizer(keyboardDismissTapGesture)
        self.keyboardDismissTapGesture = nil
    }

    @objc private func handleKeyboardDismissTap() {
        view.endEditing(true)
    }

    // MARK: - Private Methods

    private func ensureLoadingOverlayIfNeeded() {
        guard baseLoadingOverlayView.superview == nil else { return }

        view.addSubview(baseLoadingOverlayView)
        baseLoadingOverlayView.addSubview(baseLoadingView)

        baseLoadingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        baseLoadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
