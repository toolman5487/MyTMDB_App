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

class LoginViewController: UIViewController {
    
    private let viewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    
    private let indicator = UIActivityIndicatorView(style: .medium)
    
    private let logoImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "tmdb_icon")
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .clear
        return imageView
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
        textField.borderStyle = .roundedRect
        textField.text = "WillyHsu"
        return textField
    }()
    
    private let passField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Password"
        textField.text = "548798willy"
        textField.isSecureTextEntry = true
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private let loginBotton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("確認", for: .normal)
        button.titleLabel?.font = ThemeFont.bold(ofSize: 16)
        button.tintColor = .label
        button.layer.cornerRadius = 12
        button.backgroundColor = .secondarySystemBackground
        return button
    }()
    
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
        navigationItem.title = "TMDB"
        definesPresentationContext = true
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func layout(){
        view.addSubview(logoImage)
        logoImage.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(32)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        view.addSubview(loginStack)
        loginStack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(16)
        }
        userField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
        }
        passField.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        view.addSubview(loginBotton)
        loginBotton.snp.makeConstraints { make in
            make.top.equalTo(loginStack.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(48)
        }
    }
    
    private func viewmodelBind() {
        userField.textPublisher
            .compactMap { $0 }
            .assign(to: \.username, on: viewModel)
            .store(in: &cancellables)
        
        passField.textPublisher
            .compactMap { $0 }
            .assign(to: \.password, on: viewModel)
            .store(in: &cancellables)
        
        loginBotton.tapPublisher
            .sink { [weak viewModel] in
                viewModel?.loginTap.send()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .sink { [weak self] loading in
                if loading {
                    self?.indicator.startAnimating()
                } else {
                    self?.indicator.stopAnimating()
                }
                self?.loginBotton.isEnabled = !loading
            }
            .store(in: &cancellables)
        
        viewModel.$sessionId
            .compactMap { $0 }
            .sink { [weak self] sessionId in
                UserDefaults.standard.set(sessionId, forKey: "TMDBSessionID")
                guard let windowScene = self?.view.window?.windowScene,
                      let sceneDelegate = windowScene.delegate as? SceneDelegate,
                      let window = sceneDelegate.window else {
                    return
                }
                let tabBar = MainTabBarController()
                window.rootViewController = tabBar
                window.makeKeyAndVisible()
            }
            .store(in: &cancellables)
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .sink { [weak self] message in
                let alert = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
                self?.loginBotton.isEnabled = true
                self?.indicator.stopAnimating()
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        layout()
        viewmodelBind()
    }
}
