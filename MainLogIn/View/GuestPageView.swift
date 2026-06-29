//
//  GuestPageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import SnapKit
import UIKit

// MARK: - GuestPageViewDelegate

protocol GuestPageViewDelegate: AnyObject {
    func guestPageViewDidTapContinue(_ view: GuestPageView)
}

// MARK: - GuestPageView

final class GuestPageView: UIView, AuthPageView {

    // MARK: - Properties

    weak var delegate: GuestPageViewDelegate?

    let page: AuthPage = .guest

    // MARK: - UI Components

    private let cardView = UIView()

    private let descriptionLabel = AuthPageStyle.makeDescriptionLabel(
        "無需帳號即可瀏覽電影與影集，部分個人化功能將無法使用。"
    )

    private let continueButton = AuthPageStyle.makeFilledButton(title: "以訪客身分繼續")

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
