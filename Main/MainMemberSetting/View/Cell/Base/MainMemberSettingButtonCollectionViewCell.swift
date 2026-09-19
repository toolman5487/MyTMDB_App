//
//  MainMemberSettingButtonCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - MainMemberSettingButtonCollectionViewCell

@MainActor
class MainMemberSettingButtonCollectionViewCell: UICollectionViewListCell {

    // MARK: - Constants

    private enum Layout {
        static let iconSize: CGFloat = 32
        static let iconImageSize: CGFloat = 18
        static let iconCornerRadius: CGFloat = 8
        static let imageToTextPadding: CGFloat = 12
        static let rowCornerRadius: CGFloat = 12
    }

    // MARK: - Properties

    private var menuOptionSelectedHandler: ((String) -> Void)?

    // MARK: - UI Components

    private let valueLabel: UILabel = {
        let label = AppFactory.Label.subheadline(color: ThemeColor.textSecondary, alignment: .right, lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let menuButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = ThemeColor.highlight
        configuration.imagePlacement = .trailing
        configuration.imagePadding = 4
        configuration.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 8,
            bottom: 8,
            trailing: 8
        )

        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessories = []
        valueLabel.text = nil
        menuButton.menu = nil
        var menuConfiguration = menuButton.configuration
        menuConfiguration?.title = nil
        menuButton.configuration = menuConfiguration
        menuButton.accessibilityLabel = nil
        menuButton.accessibilityValue = nil
        menuButton.accessibilityHint = nil
        menuButton.isAccessibilityElement = false
        menuOptionSelectedHandler = nil
        applyAccessibilityText(nil)
        isAccessibilityElement = true
        accessibilityTraits = .none
    }

    // MARK: - Configuration

    func configure(
        with item: MainMemberSettingRowItem,
        isFirstInSection: Bool,
        isLastInSection: Bool,
        localization: AppInterfaceLocalization,
        onMenuOptionSelected: ((String) -> Void)? = nil
    ) {
        menuOptionSelectedHandler = onMenuOptionSelected
        contentConfiguration = makeContentConfiguration(for: item)
        backgroundConfiguration = makeBackgroundConfiguration()
        accessories = makeAccessories(for: item.accessory)
        configureAccessibility(for: item, localization: localization)
    }

    // MARK: - Content Configuration

    private func makeContentConfiguration(for item: MainMemberSettingRowItem) -> UIListContentConfiguration {
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

    private func iconBackgroundColor(for role: MainMemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.highlight

        case .destructive:
            return ThemeColor.systemRed
        }
    }

    private func titleColor(for role: MainMemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.textPrimary

        case .destructive:
            return ThemeColor.systemRed
        }
    }

    private func subtitleColor(for role: MainMemberSettingRowRole) -> UIColor {
        switch role {
        case .normal:
            return ThemeColor.textSecondary

        case .destructive:
            return ThemeColor.systemRed.withAlphaComponent(0.78)
        }
    }

    // MARK: - Background Configuration

    private func makeBackgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listCell()
        configuration.backgroundColor = .secondarySystemGroupedBackground
        configuration.cornerRadius = Layout.rowCornerRadius
        return configuration
    }

    // MARK: - Accessory Configuration

    private func makeAccessories(for accessory: MainMemberSettingRowAccessory) -> [UICellAccessory] {
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

        case .menu(let selectedOptionID, let options):
            configureMenuButton(
                selectedOptionID: selectedOptionID,
                options: options
            )
            return [
                .customView(
                    configuration: .init(
                        customView: menuButton,
                        placement: .trailing()
                    )
                )
            ]
        }
    }

    private func configureMenuButton(
        selectedOptionID: String,
        options: [MainMemberSettingMenuOption]
    ) {
        let selectedOption = options.first { $0.id == selectedOptionID }
        var configuration = menuButton.configuration
        configuration?.title = selectedOption?.title
        menuButton.configuration = configuration
        menuButton.menu = UIMenu(
            options: .singleSelection,
            children: options.map { option in
                UIAction(
                    title: option.title,
                    state: option.id == selectedOptionID ? .on : .off
                ) { [weak self] _ in
                    Task(priority: .userInitiated) { @MainActor [weak self] in
                        self?.menuOptionSelectedHandler?(option.id)
                    }
                }
            }
        )
    }

    // MARK: - Accessibility Configuration

    private func configureAccessibility(
        for item: MainMemberSettingRowItem,
        localization: AppInterfaceLocalization
    ) {
        valueLabel.isAccessibilityElement = false

        if case .menu(let selectedOptionID, let options) = item.accessory {
            applyAccessibilityText(nil)
            isAccessibilityElement = false
            menuButton.isAccessibilityElement = true
            menuButton.accessibilityLabel = item.title
            menuButton.accessibilityValue = options.first {
                $0.id == selectedOptionID
            }?.title
            menuButton.accessibilityHint = nil
            return
        }

        menuButton.isAccessibilityElement = false
        isAccessibilityElement = true
        applyAccessibilityText(item.accessibilityText(localization: localization))
        accessibilityTraits = item.action == nil ? .staticText : .button
    }
}
