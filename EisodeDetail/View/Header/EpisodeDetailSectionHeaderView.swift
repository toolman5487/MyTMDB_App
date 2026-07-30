//
//  EpisodeDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SnapKit
import UIKit

// MARK: - EpisodeDetailSectionHeaderView

@MainActor
final class EpisodeDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: EpisodeDetailSectionHeaderView.self)

    private let titleLabel = AppFactory.Label.sectionTitle()
    private var titleLeadingConstraint: Constraint?
    private var titleTrailingConstraint: Constraint?

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

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.attributedText = nil
        applyAccessibilityText(nil)
    }

    func configure(title: String?, contentInsets: UIEdgeInsets = .zero) {
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            font: titleLabel.font ?? UIFont.preferredFont(forTextStyle: .title3),
            textColor: ThemeColor.highlight
        )
        titleLeadingConstraint?.update(inset: contentInsets.left)
        titleTrailingConstraint?.update(inset: contentInsets.right)
        applyAccessibility(title: title)
    }

    private func setupHierarchy() {
        titleLabel.isAccessibilityElement = false
        addSubview(titleLabel)
    }

    private func applyAccessibility(title: String?) {
        guard let title = BaseDisplayTextFormatter.nonEmptyText(title) else {
            applyAccessibilityText(nil)
            return
        }

        applyAccessibilityText(
            AccessibilityText(label: "\(title) 區段")
        )
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            titleLeadingConstraint = make.leading.equalToSuperview().constraint
            titleTrailingConstraint = make.trailing.equalToSuperview().constraint
        }
    }

}
