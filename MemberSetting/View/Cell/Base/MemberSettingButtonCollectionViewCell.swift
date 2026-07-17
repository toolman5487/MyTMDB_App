//
//  MemberSettingButtonCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - MemberSettingButtonCollectionViewCell

@MainActor
class MemberSettingButtonCollectionViewCell: UICollectionViewListCell {

    // MARK: - Constants

    private enum Layout {
        static let iconSize: CGFloat = 32
        static let iconImageSize: CGFloat = 18
        static let iconCornerRadius: CGFloat = 8
        static let imageToTextPadding: CGFloat = 12
        static let rowCornerRadius: CGFloat = 12
    }

    // MARK: - Properties

    private var toggleValueChangedHandler: ((Bool) -> Void)?

    // MARK: - UI Components

    private let valueLabel: UILabel = {
        let label = AppFactory.Label.subheadline(color: ThemeColor.textSecondary, alignment: .right, lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = ThemeColor.highlight
        toggle.addTarget(self, action: #selector(handleToggleValueChanged), for: .valueChanged)
        return toggle
    }()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessories = []
        valueLabel.text = nil
        toggleSwitch.setOn(false, animated: false)
        toggleValueChangedHandler = nil
    }

    // MARK: - Configuration

    func configure(
        with item: MemberSettingRowItem,
        isFirstInSection: Bool,
        isLastInSection: Bool,
        onToggleValueChanged: ((Bool) -> Void)? = nil
    ) {
        toggleValueChangedHandler = onToggleValueChanged
        contentConfiguration = makeContentConfiguration(for: item)
        backgroundConfiguration = makeBackgroundConfiguration()
        accessories = makeAccessories(for: item.accessory)
    }

    private func makeContentConfiguration(for item: MemberSettingRowItem) -> UIListContentConfiguration {
        var configuration = defaultContentConfiguration()
        configuration.text = item.title
        configuration.secondaryText = item.subtitle
        configuration.image = makeIconImage(
            systemName: item.systemImageName,
            backgroundColor: iconBackgroundColor(for: item.role)
        )
        configuration.imageToTextPadding = Layout.imageToTextPadding
        configuration.textProperties.color = titleColor(for: item.role)
        configuration.secondaryTextProperties.color = subtitleColor(for: item.role)
        return configuration
    }

    private func makeBackgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listCell()
        configuration.backgroundColor = .secondarySystemGroupedBackground
        configuration.cornerRadius = Layout.rowCornerRadius
        return configuration
    }

    private func makeAccessories(for accessory: MemberSettingRowAccessory) -> [UICellAccessory] {
        switch accessory {
        case .none:
            return []

        case .disclosure:
            return [
                .disclosureIndicator(displayed: .always)
            ]

        case .value(let value):
            valueLabel.text = value
            return [
                .customView(
                    configuration: .init(
                        customView: valueLabel,
                        placement: .trailing()
                    )
                )
            ]

        case .toggle(let isOn):
            toggleSwitch.setOn(isOn, animated: false)
            return [
                .customView(
                    configuration: .init(
                        customView: toggleSwitch,
                        placement: .trailing()
                    )
                )
            ]
        }
    }

    private func iconBackgroundColor(for role: MemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.highlight

        case .destructive:
            return ThemeColor.systemRed
        }
    }

    private func titleColor(for role: MemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.textPrimary

        case .destructive:
            return ThemeColor.systemRed
        }
    }

    private func subtitleColor(for role: MemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.textSecondary

        case .destructive:
            return ThemeColor.systemRed.withAlphaComponent(0.78)
        }
    }

    private func makeIconImage(systemName: String, backgroundColor: UIColor) -> UIImage? {
        let size = CGSize(width: Layout.iconSize, height: Layout.iconSize)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let bounds = CGRect(origin: .zero, size: size)
            backgroundColor.setFill()
            UIBezierPath(
                roundedRect: bounds,
                cornerRadius: Layout.iconCornerRadius
            ).fill()

            guard let symbolImage = UIImage(
                systemName: systemName,
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: Layout.iconImageSize,
                    weight: .regular
                )
            )?.withTintColor(.white, renderingMode: .alwaysOriginal) else {
                return
            }

            let iconOrigin = CGPoint(
                x: (size.width - Layout.iconImageSize) / 2,
                y: (size.height - Layout.iconImageSize) / 2
            )
            symbolImage.draw(
                in: CGRect(
                    origin: iconOrigin,
                    size: CGSize(width: Layout.iconImageSize, height: Layout.iconImageSize)
                )
            )
        }
    }

    @objc private func handleToggleValueChanged(_ sender: UISwitch) {
        toggleValueChangedHandler?(sender.isOn)
    }
}
