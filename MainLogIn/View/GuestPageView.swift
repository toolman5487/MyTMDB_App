//
//  GuestPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

// MARK: - GuestPageViewDelegate

@MainActor
protocol GuestPageViewDelegate: AnyObject {
    func guestPageViewDidTapContinue(_ view: GuestPageView)
}

// MARK: - GuestPageView

final class GuestPageView: UIView, AuthPageView {

    // MARK: - Properties

    weak var delegate: GuestPageViewDelegate?

    let page: AuthPage = .guest
    private let localization: AppInterfaceLocalization

    // MARK: - UI Components

    private let cardView = UIView()

    private lazy var descriptionLabel = AuthPageStyle.makeDescriptionLabel(
        localization.string(
            "login.guest.description",
            defaultValue: "Browse movies and TV shows without an account. Some personalized features will be unavailable."
        )
    )

    private lazy var continueButton = AuthPageStyle.makeFilledButton(
        title: localization.string(
            "login.guest.continue",
            defaultValue: "Continue as Guest"
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
        continueButton.isEnabled = isEnabled
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear
        layout()
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }

    private func layout() {
        AuthPageStyle.applyCardStyle(to: cardView)
        AuthPageStyle.applyCardLayout(cardView, in: self)
        AuthPageStyle.applyActionButtonLayout(continueButton, in: cardView)
        AuthPageStyle.applyCenteredDescriptionLayout(
            symbolName: "person.crop.circle",
            label: descriptionLabel,
            in: cardView,
            above: continueButton
        )
    }

    // MARK: - Actions

    @objc private func continueTapped() {
        delegate?.guestPageViewDidTapContinue(self)
    }
}
