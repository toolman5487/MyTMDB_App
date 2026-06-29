//
//  LoginPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

// MARK: - LoginPageViewDelegate

protocol LoginPageViewDelegate: AnyObject {
    func loginPageView(_ view: LoginPageView, didUpdateUsername username: String)
    func loginPageView(_ view: LoginPageView, didUpdatePassword password: String)
    func loginPageViewDidTapLogin(_ view: LoginPageView)
}

// MARK: - LoginPageView

final class LoginPageView: UIView, AuthPageView {

    // MARK: - Properties

    weak var delegate: LoginPageViewDelegate?

    let page: AuthPage = .login

    // MARK: - UI Components

    private let cardView = UIView()

    private let userField = AuthPageStyle.makeTextField(
        placeholder: "UserID",
        contentType: .username
    )

    private let passwordToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "eye.slash"), for: .normal)
        button.tintColor = .secondaryLabel
        button.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        return button
    }()

    private let passField = AuthPageStyle.makeTextField(
        placeholder: "Password",
        contentType: .password,
        isSecure: true
    )

    private lazy var inputStack = AuthPageStyle.makeInputStack(arrangedSubviews: [userField, passField])

    private let loginButton = AuthPageStyle.makeFilledButton(title: "確認")

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - AuthPageView

    func setInteractionEnabled(_ isEnabled: Bool) {
        userField.isEnabled = isEnabled
        passField.isEnabled = isEnabled
        loginButton.isEnabled = isEnabled
        passwordToggleButton.isEnabled = isEnabled
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        layout()
        setupPasswordField()
        bindActions()
    }

    private func layout() {
        let margins = AuthPageStyle.Layout.stackMargins

        AuthPageStyle.applyCardStyle(to: cardView)
        AuthPageStyle.applyCardLayout(cardView, in: self)

        cardView.addSubview(inputStack)
        AuthPageStyle.applyActionButtonLayout(loginButton, in: cardView)

        inputStack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(margins.top)
            make.leading.trailing.equalToSuperview().inset(margins.left)
            make.bottom.lessThanOrEqualTo(loginButton.snp.top).offset(-AuthPageStyle.Layout.stackSpacing)
        }

        AuthPageStyle.applyFieldHeight(userField)
        AuthPageStyle.applyFieldHeight(passField)
    }

    private func setupPasswordField() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 24))
        container.addSubview(passwordToggleButton)
        passwordToggleButton.center = container.center
        passField.rightView = container
        passField.rightViewMode = .always
        passwordToggleButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
    }

    private func bindActions() {
        userField.addTarget(self, action: #selector(usernameDidChange), for: .editingChanged)
        passField.addTarget(self, action: #selector(passwordDidChange), for: .editingChanged)
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func usernameDidChange() {
        delegate?.loginPageView(self, didUpdateUsername: userField.text ?? "")
    }

    @objc private func passwordDidChange() {
        delegate?.loginPageView(self, didUpdatePassword: passField.text ?? "")
    }

    @objc private func loginTapped() {
        endEditing(true)
        delegate?.loginPageViewDidTapLogin(self)
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
}
