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

    var preferredBackgroundColor: UIColor {
        ThemeColor.background
    }

    private var keyboardDismissTapGesture: UITapGestureRecognizer?

    private lazy var baseLoadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.background.withAlphaComponent(0.4)
        view.isHidden = true
        view.alpha = 0
        return view
    }()

    private lazy var baseLoadingIndicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .large)
        indicatorView.color = ThemeColor.primary
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = preferredBackgroundColor
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
            baseLoadingIndicatorView.startAnimating()
            UIView.animate(withDuration: 0.2, animations: updates)

        case (true, false):
            baseLoadingOverlayView.isHidden = false
            baseLoadingIndicatorView.startAnimating()
            updates()

        case (false, true):
            UIView.animate(withDuration: 0.2, animations: updates) { [weak self] _ in
                self?.baseLoadingOverlayView.isHidden = true
                self?.baseLoadingIndicatorView.stopAnimating()
            }

        case (false, false):
            updates()
            baseLoadingOverlayView.isHidden = true
            baseLoadingIndicatorView.stopAnimating()
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
        baseLoadingOverlayView.addSubview(baseLoadingIndicatorView)

        baseLoadingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        baseLoadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}
