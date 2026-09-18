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

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let disclosureSymbolName = "chevron.right"
    }

    // MARK: - Override Points

    var titleHorizontalInset: CGFloat {
        Layout.horizontalInset
    }

    // MARK: - Properties

    private var onTitleTap: (() -> Void)?

    // MARK: - UI Components

    let titleRowView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let titleLabel = AppFactory.Label.sectionTitle(color: ThemeColor.highlight)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupTitleRow()
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTitleRow()
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: nil)
        resetForReuse()
    }

    // MARK: - Template Methods

    func configureView() {
        backgroundColor = .clear
    }

    func setupHierarchy() {
        addSubview(titleRowView)
    }

    func setupConstraints() {
        titleRowView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    func resetForReuse() {}

    func titleAccessibilityText(for title: String, isTappable: Bool) -> AccessibilityText {
        AccessibilityText(label: title)
    }

    // MARK: - Configuration

    func configure(title: String?, onTitleTap: (() -> Void)? = nil) {
        self.onTitleTap = onTitleTap

        let isTappable = onTitleTap != nil
        let font = titleLabel.font ?? .preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            trailingImage: isTappable ? Self.makeDisclosureImage(font: font) : nil,
            font: font,
            textColor: ThemeColor.highlight,
            trailingImageColor: ThemeColor.textSecondary
        )
        titleRowView.isUserInteractionEnabled = isTappable
        applyTitleAccessibility(title: title, isTappable: isTappable)
    }

    // MARK: - Private Methods

    private func setupTitleRow() {
        titleLabel.isAccessibilityElement = false
        titleRowView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(titleHorizontalInset)
        }
        titleRowView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        )
    }

    private func applyTitleAccessibility(title: String?, isTappable: Bool) {
        guard let title = BaseDisplayTextFormatter.nonEmptyText(title) else {
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
            systemName: Layout.disclosureSymbolName,
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    @objc private func handleTitleTap() {
        onTitleTap?()
    }
}
