//
//  TVDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - TVDetailSectionHeaderView

@MainActor
final class TVDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailSectionHeaderView.self)

    private var onTap: (() -> Void)?

    private let titleLabel = AppFactory.Label.sectionTitle()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: nil)
    }

    func configure(title: String?, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        let font = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            trailingImage: onTap != nil ? makeTitleTrailingImage(font: font) : nil,
            font: font,
            textColor: ThemeColor.highlight
        )
        isUserInteractionEnabled = onTap != nil
        applyAccessibility(title: title, isTappable: onTap != nil)
    }

    private func configureView() {
        backgroundColor = .clear
        titleLabel.isAccessibilityElement = false
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }
    }

    private func makeTitleTrailingImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: "chevron.right.2",
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    private func applyAccessibility(title: String?, isTappable: Bool) {
        guard let title = BaseDisplayTextFormatter.nonEmptyText(title) else {
            applyAccessibilityText(nil)
            accessibilityTraits.remove(.button)
            return
        }

        applyAccessibilityText(
            AccessibilityText(
                label: "\(title) 區段",
                hint: isTappable ? "點兩下查看完整列表" : nil
            )
        )

        if isTappable {
            accessibilityTraits.insert(.button)
        } else {
            accessibilityTraits.remove(.button)
        }
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}
