//
//  RegisterPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit
import SnapKit

// MARK: - RegisterPageViewDelegate

protocol RegisterPageViewDelegate: AnyObject {
    func registerPageViewDidTapRegister(_ view: RegisterPageView)
}

// MARK: - RegisterPageView

final class RegisterPageView: UIView, AuthPageView {

    // MARK: - Properties

    weak var delegate: RegisterPageViewDelegate?

    let page: AuthPage = .register

    // MARK: - UI Components

    private let descriptionLabel = AuthPageStyle.makeDescriptionLabel(
        "前往 TMDB 官網建立帳號，即可使用收藏、待看清單等功能。"
    )

    private let registerButton = AuthPageStyle.makeFilledButton(title: "前往註冊")

    private lazy var formStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [descriptionLabel, registerButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        AuthPageStyle.applyCardStyle(to: stack)
        return stack
    }()

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
        registerButton.isEnabled = isEnabled
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        layout()
        registerButton.addTarget(self, action: #selector(registerTapped), for: .touchUpInside)
    }

    private func layout() {
        addSubview(formStack)

        formStack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }

        registerButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    // MARK: - Actions

    @objc private func registerTapped() {
        delegate?.registerPageViewDidTapRegister(self)
    }
}
