//
//  BaseSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/18.
//

import SnapKit
import UIKit

// MARK: - BaseSectionHeaderView

@MainActor
class BaseSectionHeaderView: UICollectionReusableView {

    class var reuseIdentifier: String {
        String(describing: self)
    }

    // MARK: - Constants

    private static let disclosureSymbolName = "chevron.right"

    // MARK: - Properties

    private var onTitleTap: (() -> Void)?
    private(set) var interfaceLocalization: AppInterfaceLocalization = .traditionalChinese

    // MARK: - UI Components

    private(set) lazy var titleRowView: UIView = {
        let view = SectionHeaderTitleRowView()
        view.onTap = { [weak self] in
            self?.onTitleTap?()
        }
        return view
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.sectionTitle(color: ThemeColor.highlight)
        label.font = BaseSectionHeaderView.sectionTitleFont
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitleRow()
        configureView()
        setupHierarchy()
        placeTitleRow()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTitleRow()
        configureView()
        setupHierarchy()
        placeTitleRow()
        setupConstraints()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: nil, localization: interfaceLocalization)
        resetForReuse()
    }

    // MARK: - Template Methods

    func configureView() {
        backgroundColor = ThemeColor.clear
    }

    func setupHierarchy() {}

    func placeTitleRow() {
        addSubview(titleRowView)
        titleRowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func setupConstraints() {}

    func resetForReuse() {}

    func titleAccessibilityText(for title: String, isTappable: Bool) -> AccessibilityText {
        AccessibilityText(label: title)
    }

    // MARK: - Configuration

    func configure(
        title: String?,
        localization: AppInterfaceLocalization,
        onTitleTap: (() -> Void)? = nil
    ) {
        interfaceLocalization = localization
        let displayTitle = BaseDisplayTextFormatter.nonEmptyText(title)
        let titleTapHandler = displayTitle == nil ? nil : onTitleTap
        let isTappable = titleTapHandler != nil
        self.onTitleTap = titleTapHandler

        let font = titleLabel.font ?? .preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: displayTitle,
            trailingImage: isTappable ? Self.makeDisclosureImage(font: font) : nil,
            font: font,
            textColor: ThemeColor.highlight,
            trailingImageColor: ThemeColor.textSecondary
        )
        titleRowView.isUserInteractionEnabled = isTappable
        applyTitleAccessibility(title: displayTitle, isTappable: isTappable)
    }

    // MARK: - Private Methods

    private func setupTitleRow() {
        titleLabel.isAccessibilityElement = false
        titleRowView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(SectionHeaderLayoutMetrics.horizontalInset)
        }
    }

    private func applyTitleAccessibility(title: String?, isTappable: Bool) {
        guard let title else {
            titleRowView.applyAccessibilityText(nil)
            titleRowView.accessibilityTraits.remove(.button)
            return
        }

        titleRowView.applyAccessibilityText(
            titleAccessibilityText(for: title, isTappable: isTappable)
        )

        if isTappable {
            titleRowView.accessibilityTraits.insert(.button)
        } else {
            titleRowView.accessibilityTraits.remove(.button)
        }
    }

    private static func makeDisclosureImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: disclosureSymbolName,
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    private static var sectionTitleFont: UIFont {
        UIFontMetrics(forTextStyle: .title3).scaledFont(
            for: .systemFont(ofSize: 20, weight: .bold)
        )
    }
}

// MARK: - SectionHeaderTitleRowView

@MainActor
private final class SectionHeaderTitleRowView: UIView {

    // MARK: - Properties

    var onTap: (() -> Void)?

    // MARK: - Touch Handling

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isTouchInside(touches) else { return }
        onTap?()
    }

    private func isTouchInside(_ touches: Set<UITouch>) -> Bool {
        guard let touch = touches.first else { return false }
        return bounds.contains(touch.location(in: self))
    }
}
