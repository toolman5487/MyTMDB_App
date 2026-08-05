//
//  DetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/30.
//

import SnapKit
import UIKit

// MARK: - DetailSectionHeaderView

@MainActor
final class DetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: DetailSectionHeaderView.self)

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

    func configure(
        title: String?,
        onTap: (() -> Void)? = nil
    ) {
        self.onTap = onTap

        let font = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            trailingImage: onTap == nil ? nil : makeTrailingImage(font: font),
            font: font,
            textColor: ThemeColor.highlight
        )

        let isTappable = onTap != nil
        isUserInteractionEnabled = isTappable
        applyAccessibility(title: title, isTappable: isTappable)
    }

    private func configureView() {
        backgroundColor = .clear
        titleLabel.isAccessibilityElement = false
        addGestureRecognizer(
            UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap)
            )
        )
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(DetailLayoutMetrics.horizontalContentInset)
        }
    }

    private func makeTrailingImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: "chevron.right.2",
            withConfiguration: UIImage.SymbolConfiguration(
                font: font,
                scale: .small
            )
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
