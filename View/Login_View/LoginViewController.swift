//
//  LoginViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import SnapKit
import Combine
import CombineCocoa
import SafariServices

class LoginViewController: UIViewController {
    
    private let loginVM = LoginViewModel()
    let accountVM = AccountViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let indicator = UIActivityIndicatorView(style: .medium)
    
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
        label.font = ThemeFont.bold(ofSize: 30)
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
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.textContentType = .username
        textField.autocapitalizationType = .none
        return textField
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
        textField.font = UIFont.systemFont(ofSize: 18)
        textField.textContentType = .password
        
        let eyeButton = UIButton(type: .system)
        eyeButton.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        eyeButton.tintColor = .secondaryLabel
        eyeButton.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        eyeButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        container.addSubview(eyeButton)
        eyeButton.center = container.center
        textField.rightView = container
        textField.rightViewMode = .always
        return textField
    }()
    
    @objc private func togglePasswordVisibility(_ sender: UIButton) {
        passField.isSecureTextEntry.toggle()
        let imageName = passField.isSecureTextEntry ? "eye.slash" : "eye.circle"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    private let loginBotton: UIButton = {
        var config = UIButton.Configuration.filled()
        var attribute = AttributedString("確認")
        attribute.font = ThemeFont.bold(ofSize: 16)
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
        attribute.font = ThemeFont.bold(ofSize: 16)
        config.attributedTitle = attribute
        config.baseBackgroundColor = .label
        config.baseForegroundColor = .systemBackground
        let button = UIButton(configuration: config, primaryAction: nil)
        button.layer.cornerRadius = 20
        button.clipsToBounds = true
        return button
    }()
    
    @objc private func goToRegister() {
        guard let url = URL(string: "https://www.themoviedb.org/signup") else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    lazy var loginStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [headerLabel,userField, passField])
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
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func layout(){
        view.addSubview(loginStack)
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
        
        view.addSubview(logoImage)
        logoImage.snp.makeConstraints { make in
            make.bottom.equalTo(loginStack.snp.top).offset(-16)
            make.leading.trailing.equalTo(loginStack)
            make.height.equalTo(100)
        }
        
        view.addSubview(loginBotton)
        loginBotton.snp.makeConstraints { make in
            make.top.equalTo(loginStack.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
        
        view.addSubview(registerButton)
        registerButton.snp.makeConstraints { make in
            make.top.equalTo(loginBotton.snp.bottom).offset(8)
            make.centerX.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    
    private func bindingViewmodel() {
        userField.textPublisher
            .compactMap { $0 }
            .assign(to: \.username, on: loginVM)
            .store(in: &cancellables)
        
        passField.textPublisher
            .compactMap { $0 }
            .assign(to: \.password, on: loginVM)
            .store(in: &cancellables)
        
        loginBotton.tapPublisher
            .sink { [weak self] in
                self?.loginVM.loginTap.send()
            }
            .store(in: &cancellables)
        
        loginVM.$isLoading
            .sink { [weak self] loading in
                if loading {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
                self?.loginBotton.isEnabled = !loading
            }
            .store(in: &cancellables)
        
        loginVM.$sessionId
            .compactMap { $0 }
            .sink { [weak self] sessionId in
                UserDefaults.standard.set(sessionId, forKey: "TMDBSessionID")
                print("Session ID:", sessionId)
                self?.accountVM.loadAccount(sessionId: sessionId)
            }
            .store(in: &cancellables)
        
        loginVM.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
                self?.loginBotton.isEnabled = true
                self?.indicator.stopAnimating()
            }
            .store(in: &cancellables)
        
        accountVM.$account
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] account in
                guard let windowScene = self?.view.window?.windowScene,
                      let sceneDelegate = windowScene.delegate as? SceneDelegate,
                      let window = sceneDelegate.window else {
                  return
                }
                let sessionId = UserDefaults.standard.string(forKey: "TMDBSessionID") ?? ""
                let tabBar = MainTabBarController(accountId: account.id, sessionId: sessionId)
                window.rootViewController = tabBar
                window.makeKeyAndVisible()
            }
            .store(in: &cancellables)
        
        registerButton.addTarget(self, action: #selector(goToRegister), for: .touchUpInside)
    }
    
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        super.viewDidLoad()
        setupNavigationBar()
        layout()
        bindingViewmodel()
    }
}
