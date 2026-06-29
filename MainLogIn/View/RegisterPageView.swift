//
//  RegisterPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

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

    private let cardView = UIView()

    private let descriptionLabel = AuthPageStyle.makeDescriptionLabel(
        "前往 TMDB 官網建立帳號，即可使用收藏、待看清單等功能。"
    )

    private let registerButton = AuthPageStyle.makeFilledButton(title: "前往註冊")

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
        AuthPageStyle.applyCardStyle(to: cardView)
        AuthPageStyle.applyCardLayout(cardView, in: self)
        AuthPageStyle.applyActionButtonLayout(registerButton, in: cardView)
        AuthPageStyle.applyCenteredDescriptionLayout(
            symbolName: "person.crop.circle.badge.plus",
            label: descriptionLabel,
            in: cardView,
            above: registerButton
        )
    }

    // MARK: - Actions

    @objc private func registerTapped() {
        delegate?.registerPageViewDidTapRegister(self)
    }
}
