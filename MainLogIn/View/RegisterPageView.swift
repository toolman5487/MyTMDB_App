//
//  RegisterPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

// MARK: - RegisterPageViewDelegate

@MainActor
protocol RegisterPageViewDelegate: AnyObject {
    func registerPageViewDidTapRegister(_ view: RegisterPageView)
}

// MARK: - RegisterPageView

final class RegisterPageView: UIView, AuthPageView {

    // MARK: - Properties

    weak var delegate: RegisterPageViewDelegate?

    let page: AuthPage = .register
    private let localization: AppInterfaceLocalization

    // MARK: - UI Components

    private let cardView = UIView()

    private lazy var descriptionLabel = AuthPageStyle.makeDescriptionLabel(
        localization.string(
            "login.register.description",
            defaultValue: "Create an account on the TMDB website to use favorites, watchlists, and more."
        )
    )

    private lazy var registerButton = AuthPageStyle.makeFilledButton(
        title: localization.string(
            "login.register.open_website",
            defaultValue: "Go to Registration"
        )
    )

    // MARK: - Initialization

    init(
        localization: AppInterfaceLocalization,
        frame: CGRect = .zero
    ) {
        self.localization = localization
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
        backgroundColor = ThemeColor.clear
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
