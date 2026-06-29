//
//  ViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import SnapKit
import UIKit

@MainActor
final class ViewController: BaseViewController {

    // MARK: - Properties

    private let sessionStore: SessionStoring = SessionStore()

    // MARK: - UI Components

    private lazy var logoutButton: UIButton = {
        var config = UIButton.Configuration.filled()
        var title = AttributedString("登出")
        title.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = title
        config.baseBackgroundColor = ThemeColor.systemRed
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Template Methods

    override func configureView() {
        title = "MyTMDB"
    }

    override func setupHierarchy() {
        view.addSubview(logoutButton)
    }

    override func setupConstraints() {
        logoutButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
            make.height.equalTo(48)
        }
    }

    // MARK: - Actions

    @objc private func logoutButtonTapped() {
        let alert = UIAlertController(
            title: "登出",
            message: "確定要登出嗎？",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "登出", style: .destructive) { [weak self] _ in
            self?.performLogout()
        })
        present(alert, animated: true)
    }

    // MARK: - Logout

    private func performLogout() {
        sessionStore.clear()
        navigateToLoginScreen()
    }

    private func navigateToLoginScreen() {
        guard let windowScene = view.window?.windowScene,
              let sceneDelegate = windowScene.delegate as? SceneDelegate,
              let window = sceneDelegate.window else {
            return
        }
        AppRootFactory.replaceRoot(in: window, for: .loggedOut)
    }
}
