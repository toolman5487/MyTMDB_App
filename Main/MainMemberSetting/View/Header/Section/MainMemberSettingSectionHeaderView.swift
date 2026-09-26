//
//  MainMemberSettingSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/16.
//

import UIKit

// MARK: - MainMemberSettingSectionHeaderView

@MainActor
final class MainMemberSettingSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 4
    }

    // MARK: - Properties

    static let reuseIdentifier = String(describing: MainMemberSettingSectionHeaderView.self)

    // MARK: - UI Components

    private let titleLabel = AppFactory.Label.footnote(color: ThemeColor.textSecondary, lines: 1)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        applyAccessibilityText(nil)
        accessibilityTraits.remove(.header)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let labelHeight = titleLabel.intrinsicContentSize.height
        titleLabel.frame = CGRect(
            x: Layout.horizontalInset,
            y: bounds.height - Layout.bottomInset - labelHeight,
            width: bounds.width - Layout.horizontalInset * 2,
            height: labelHeight
        )
    }

    // MARK: - Configuration

    func configure(
        title: String?,
        localization: AppInterfaceLocalization
    ) {
        let trimmedTitle = BaseDisplayTextFormatter.nonEmptyText(title)
        titleLabel.text = trimmedTitle?.uppercased()
        applyAccessibility(title: trimmedTitle, localization: localization)
        setNeedsLayout()
    }

    private func applyAccessibility(
        title: String?,
        localization: AppInterfaceLocalization
    ) {
        guard let title else {
            applyAccessibilityText(nil)
            accessibilityTraits.remove(.header)
            return
        }

        let labelFormat = localization.string(
            "main_member_setting.section.accessibility.label_format",
            defaultValue: "%@ settings"
        )
        applyAccessibilityText(AccessibilityText(
            label: String(format: labelFormat, locale: localization.language.locale, title)
        ))
        accessibilityTraits.insert(.header)
        titleLabel.isAccessibilityElement = false
    }

    private func configureView() {
        backgroundColor = ThemeColor.clear
        addSubview(titleLabel)
    }
}
