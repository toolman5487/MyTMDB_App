//
//  SearchSubmittedLoadingView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - SearchSubmittedLoadingView

@MainActor
final class SearchSubmittedLoadingView: UIView {

    private let animationView = AppFactory.Animation.searchLoading(size: AppAnimationView.Metrics.searchSize)

    private let titleLabel = AppFactory.Label.headline(alignment: .center, lines: 0)

    private let messageLabel = AppFactory.Label.subheadline(alignment: .center, lines: 0)

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            animationView,
            titleLabel,
            messageLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 8
        return stackView
    }()

    private let localization: AppInterfaceLocalization

    init(
        keyword: String,
        localization: AppInterfaceLocalization
    ) {
        self.localization = localization
        super.init(frame: .zero)
        titleLabel.text = localization.string("search.loading.title", defaultValue: "Searching")
        messageLabel.text = localization.formatted(
            "search.loading.message_format",
            defaultValue: "Searching for “%@”",
            keyword
        )
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(24)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }
        animationView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        messageLabel.isAccessibilityElement = false
        applyAccessibilityText(
            AccessibilityText(
                label: titleLabel.text ?? localization.string(
                    "search.loading.title",
                    defaultValue: "Searching"
                ),
                value: messageLabel.text
            )
        )
        accessibilityTraits.insert(.updatesFrequently)
    }
}
