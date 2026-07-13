//
//  ErrorMessageView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation
import SnapKit
import UIKit

// MARK: - ErrorMessageView

@MainActor
final class ErrorMessageView: UIView {

    // MARK: - Properties

    private var action: (() -> Void)?

    // MARK: - UI Components

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        imageView.setContentHuggingPriority(.required, for: .vertical)
        return imageView
    }()

    private let titleLabel = AppFactory.Label.headline(alignment: .center, lines: 0)

    private let messageLabel = AppFactory.Label.body(alignment: .center, lines: 0)

    private lazy var actionButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = ThemeColor.primary
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(handleActionButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            imageView,
            titleLabel,
            messageLabel,
            actionButton
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    convenience init(message: ErrorMessage, action: (() -> Void)? = nil) {
        self.init(frame: .zero)
        configure(with: message, action: action)
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(stackView)
    }

    private func setupConstraints() {
        imageView.snp.makeConstraints { make in
            make.size.equalTo(40)
        }

        actionButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(44)
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
    }

    // MARK: - Configuration

    func configure(with message: ErrorMessage, action: (() -> Void)? = nil) {
        self.action = action
        imageView.image = UIImage(systemName: message.systemImageName)
        titleLabel.text = message.title
        messageLabel.text = message.message

        if let actionTitle = message.actionTitle, action != nil {
            actionButton.configuration?.title = actionTitle
            actionButton.isHidden = false
        } else {
            actionButton.configuration?.title = nil
            actionButton.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func handleActionButtonTapped() {
        action?()
    }
}
