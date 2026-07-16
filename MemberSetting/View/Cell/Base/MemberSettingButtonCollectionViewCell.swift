//
//  MemberSettingButtonCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import SnapKit
import UIKit

// MARK: - MemberSettingButtonCollectionViewCell

@MainActor
class MemberSettingButtonCollectionViewCell: BaseCollectionViewCell {

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let contentLeadingInset: CGFloat = 12
        static let contentTrailingInset: CGFloat = 12
        static let iconSize: CGFloat = 32
        static let iconImageSize: CGFloat = 20
        static let iconCornerRadius: CGFloat = 8
        static let rowCornerRadius: CGFloat = 12
        static let textStackSpacing: CGFloat = 4
        static let disclosureSymbolPointSize: CGFloat = 12
        static let disclosureImageSize: CGFloat = 16
    }

    // MARK: - Properties

    private var rowMask: CACornerMask = []
    private var toggleValueChangedHandler: ((Bool) -> Void)?

    // MARK: - UI Components

    private let rowContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerCurve = .continuous
        view.layer.masksToBounds = true
        return view
    }()

    private let iconContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.highlight
        AppFactory.View.applyRoundedCorners(to: view, radius: Layout.iconCornerRadius)
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()

    private let titleLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 1)

    private let subtitleLabel = AppFactory.Label.captionSecondary(color: ThemeColor.textSecondary, lines: 1)

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            subtitleLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Layout.textStackSpacing
        return stackView
    }()

    private let valueLabel = AppFactory.Label.subheadline(color: ThemeColor.textSecondary, alignment: .right, lines: 1)

    private let disclosureImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        imageView.image = UIImage(
            systemName: "chevron.right",
            withConfiguration: UIImage.SymbolConfiguration(
                pointSize: Layout.disclosureSymbolPointSize,
                weight: .semibold
            )
        )
        return imageView
    }()

    private lazy var toggleSwitch: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = ThemeColor.highlight
        toggle.addTarget(self, action: #selector(handleToggleValueChanged), for: .valueChanged)
        return toggle
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconContainerView,
            textStackView,
            valueLabel,
            toggleSwitch,
            disclosureImageView
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 12
        return stackView
    }()

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.12) {
                self.rowContainerView.alpha = self.isHighlighted ? 0.72 : 1
            }
        }
    }

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggleSwitch.setContentHuggingPriority(.required, for: .horizontal)
        toggleSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        disclosureImageView.setContentHuggingPriority(.required, for: .horizontal)
        disclosureImageView.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(rowContainerView)
        rowContainerView.addSubview(contentStackView)
        rowContainerView.addSubview(separatorView)
        iconContainerView.addSubview(iconImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        rowContainerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
        }

        iconContainerView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.iconImageSize)
            make.center.equalToSuperview()
        }

        contentStackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.equalToSuperview().offset(Layout.contentLeadingInset)
            make.trailing.equalToSuperview().offset(-Layout.contentTrailingInset)
        }

        disclosureImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.disclosureImageSize)
        }

        separatorView.snp.makeConstraints { make in
            make.height.equalTo(1.0 / UIScreen.main.scale)
            make.leading.equalTo(textStackView.snp.leading)
            make.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
        valueLabel.text = nil
        valueLabel.isHidden = true
        toggleSwitch.isHidden = true
        toggleSwitch.isOn = false
        disclosureImageView.isHidden = true
        separatorView.isHidden = false
        iconImageView.image = nil
        rowContainerView.backgroundColor = .secondarySystemGroupedBackground
        iconContainerView.backgroundColor = ThemeColor.highlight
        iconImageView.tintColor = .white
        titleLabel.textColor = ThemeColor.textPrimary
        subtitleLabel.textColor = ThemeColor.textSecondary
        rowMask = []
        toggleValueChangedHandler = nil
        accessibilityLabel = nil
        accessibilityTraits = []
    }

    // MARK: - Configuration

    func configure(
        with item: MemberSettingRowItem,
        isFirstInSection: Bool,
        isLastInSection: Bool,
        onToggleValueChanged: ((Bool) -> Void)? = nil
    ) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle == nil
        iconImageView.image = UIImage(systemName: item.systemImageName)
        toggleValueChangedHandler = onToggleValueChanged
        configureAccessory(item.accessory)
        configureRole(item.role)
        configureCorners(isFirstInSection: isFirstInSection, isLastInSection: isLastInSection)
        separatorView.isHidden = isLastInSection
        accessibilityLabel = makeAccessibilityLabel(for: item)
        accessibilityTraits = [.button]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        rowContainerView.layer.cornerRadius = Layout.rowCornerRadius
        rowContainerView.layer.maskedCorners = rowMask
    }

    private func configureAccessory(_ accessory: MemberSettingRowAccessory) {
        switch accessory {
        case .none:
            valueLabel.isHidden = true
            toggleSwitch.isHidden = true
            disclosureImageView.isHidden = true

        case .disclosure:
            valueLabel.isHidden = true
            toggleSwitch.isHidden = true
            disclosureImageView.isHidden = false

        case .value(let value):
            valueLabel.text = value
            valueLabel.isHidden = false
            toggleSwitch.isHidden = true
            disclosureImageView.isHidden = true

        case .toggle(let isOn):
            valueLabel.isHidden = true
            toggleSwitch.isHidden = false
            toggleSwitch.setOn(isOn, animated: false)
            disclosureImageView.isHidden = true
        }
    }

    private func configureRole(_ role: MemberSettingRowRole) {
        switch role {
        case .normal:
            rowContainerView.backgroundColor = .secondarySystemGroupedBackground
            iconContainerView.backgroundColor = ThemeColor.highlight
            iconImageView.tintColor = .white
            titleLabel.textColor = ThemeColor.textPrimary
            subtitleLabel.textColor = ThemeColor.textSecondary

        case .destructive:
            rowContainerView.backgroundColor = .secondarySystemGroupedBackground
            iconContainerView.backgroundColor = ThemeColor.systemRed
            iconImageView.tintColor = .white
            titleLabel.textColor = ThemeColor.systemRed
            subtitleLabel.textColor = ThemeColor.systemRed.withAlphaComponent(0.78)
        }
    }

    private func configureCorners(isFirstInSection: Bool, isLastInSection: Bool) {
        var mask: CACornerMask = []

        if isFirstInSection {
            mask.insert(.layerMinXMinYCorner)
            mask.insert(.layerMaxXMinYCorner)
        }

        if isLastInSection {
            mask.insert(.layerMinXMaxYCorner)
            mask.insert(.layerMaxXMaxYCorner)
        }

        rowMask = mask
        setNeedsLayout()
    }

    private func makeAccessibilityLabel(for item: MemberSettingRowItem) -> String {
        switch item.accessory {
        case .value(let value):
            return "\(item.title)，\(value)"

        case .toggle(let isOn):
            return "\(item.title)，\(isOn ? "開啟" : "關閉")"

        case .none, .disclosure:
            guard let subtitle = item.subtitle else { return item.title }
            return "\(item.title)，\(subtitle)"
        }
    }

    @objc private func handleToggleValueChanged(_ sender: UISwitch) {
        toggleValueChangedHandler?(sender.isOn)
    }
}
