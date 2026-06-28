//
//  LoginViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import SnapKit
import SafariServices
import Lottie
import Observation

class LoginViewController: UIViewController {

    // MARK: - Properties

    private let loginVM = LoginViewModel()
    let accountVM = AccountViewModel()

    // MARK: - UI Components

    private let animationView: LottieAnimationView = {
        let view = LottieAnimationView(name: "loadingAir")
        view.loopMode = .loop
        view.contentMode = .scaleAspectFit
        view.isHidden = true
        return view
    }()

    private let loadingOverlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.4)
        view.isHidden = true
        return view
    }()

    private let logoImage: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "tmdb_icon_long")
        image.clipsToBounds = true
        image.contentMode = .scaleAspectFill
        image.layer.cornerRadius = 10
        return image
    }()

    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "登入"
        label.font = UIFont.preferredFont(forTextStyle: .title1)
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let userField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "UserID"
        textField.text = ""
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.secondaryLabel.cgColor
        textField.layer.cornerRadius = 8
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textContentType = .username
        textField.autocapitalizationType = .none
        return textField
    }()

    private let passwordToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .secondaryLabel
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        return button
    }()

    private let passField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.text = ""
        textField.isSecureTextEntry = true
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.secondaryLabel.cgColor
        textField.layer.cornerRadius = 8
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.textContentType = .password
        return textField
    }()

    private let loginBotton: UIButton = {
        var config = UIButton.Configuration.filled()
        var attribute = AttributedString("確認")
        attribute.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = attribute
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .medium
        let button = UIButton(configuration: config, primaryAction: nil)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private let registerButton: UIButton = {
        var config = UIButton.Configuration.filled()
        var attribute = AttributedString("註冊")
        attribute.font = UIFont.preferredFont(forTextStyle: .headline)
        config.attributedTitle = attribute
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        config.cornerStyle = .medium
        let button = UIButton(configuration: config, primaryAction: nil)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()

    private lazy var actionButtonStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [loginBotton, registerButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        return stack
    }()

    private lazy var loginStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerLabel, userField, passField])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.distribution = .fill
        stack.backgroundColor = .secondarySystemBackground
        stack.layer.cornerRadius = 12
        stack.layer.masksToBounds = true
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        return stack
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        super.viewDidLoad()
        setupNavigationBar()
        layout()
        setupPasswordField()
        bindingViewmodel()
    }

    // MARK: - Setup

    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func setupPasswordField() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        container.addSubview(passwordToggleButton)
        passwordToggleButton.center = container.center
        passField.rightView = container
        passField.rightViewMode = .always
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
    }

    private func bindingViewmodel() {
        userField.addTarget(self, action: #selector(usernameDidChange), for: .editingChanged)
        passField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)
        loginBotton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        registerButton.addTarget(self, action: #selector(goToRegister), for: .touchUpInside)

        handleLoginState(loginVM.state)
        handleAccountState(accountVM.state)
        observeLoginState()
        observeAccountState()
    }

    // MARK: - Layout

    private func layout() {
        view.addSubview(loginStack)
        view.addSubview(logoImage)
        view.addSubview(actionButtonStack)
        view.addSubview(loadingOverlayView)
        view.addSubview(animationView)

        loginStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }

        userField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(56)
        }

        passField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(56)
        }

        logoImage.snp.makeConstraints { make in
            make.bottom.equalTo(loginStack.snp.top).offset(-16)
            make.leading.trailing.equalTo(loginStack)
            make.height.equalTo(100)
        }

        actionButtonStack.snp.makeConstraints { make in
            make.top.equalTo(loginStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }

        loadingOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        animationView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(300)
        }
    }

    // MARK: - Actions

    @objc private func usernameDidChange() {
        loginVM.username = userField.text ?? ""
    }

    @objc private func passwordDidChange() {
        loginVM.password = passField.text ?? ""
    }

    @objc private func loginTapped() {
        Task(priority: .userInitiated) {
            await loginVM.login()
        }
    }

    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        let existingText = passField.text
        let selectedRange = passField.selectedTextRange

        passField.isSecureTextEntry.toggle()
        passField.text = existingText
        passField.selectedTextRange = selectedRange

        let imageName = passField.isSecureTextEntry ? "eye.slash" : "eye"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @objc private func goToRegister() {
        guard let url = URL(string: "https://www.themoviedb.org/signup") else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }

    // MARK: - Observation

    private func observeLoginState() {
        withObservationTracking {
            _ = loginVM.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor in
                guard let self else { return }
                self.handleLoginState(self.loginVM.state)
                self.observeLoginState()
            }
        }
    }

    private func observeAccountState() {
        withObservationTracking {
            _ = accountVM.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor in
                guard let self else { return }
                self.handleAccountState(self.accountVM.state)
                self.observeAccountState()
            }
        }
    }

    // MARK: - State Handling

    private func handleLoginState(_ state: LoginState) {
        switch state {
        case .idle:
            setLoadingOverlayVisible(false)
            loginBotton.isEnabled = true

        case .loading:
            setLoadingOverlayVisible(true)
            loginBotton.isEnabled = false

        case .success(let sessionId):
            setLoadingOverlayVisible(true)
            loginBotton.isEnabled = false
            UserDefaults.standard.set(sessionId, forKey: "TMDBSessionID")
            Task(priority: .userInitiated) {
                await accountVM.loadAccount(sessionId: sessionId)
            }

        case .failed(let message):
            setLoadingOverlayVisible(false)
            loginBotton.isEnabled = true
            presentAlert(title: "Login Failed", message: message)
        }
    }

    private func handleAccountState(_ state: AccountState) {
        switch state {
        case .idle:
            break

        case .loading:
            setLoadingOverlayVisible(true)
            loginBotton.isEnabled = false

        case .loaded:
            setLoadingOverlayVisible(false)
            guard let windowScene = view.window?.windowScene,
                  let sceneDelegate = windowScene.delegate as? SceneDelegate,
                  let window = sceneDelegate.window else {
                return
            }
            window.rootViewController = ViewController()
            window.makeKeyAndVisible()

        case .failed(let message):
            setLoadingOverlayVisible(false)
            loginBotton.isEnabled = true
            presentAlert(title: "載入帳號失敗", message: message)
        }
    }

    // MARK: - Helpers

    private func setLoadingOverlayVisible(_ visible: Bool) {
        loadingOverlayView.isHidden = !visible
        animationView.isHidden = !visible

        switch visible {
        case true:
            animationView.play()
        case false:
            animationView.stop()
        }
    }

    private func presentAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
