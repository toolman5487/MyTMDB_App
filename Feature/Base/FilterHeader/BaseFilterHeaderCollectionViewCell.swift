//
//  BaseFilterHeaderCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import SkeletonView
import SnapKit
import UIKit

// MARK: - BaseFilterHeaderCollectionViewCell

@MainActor
class BaseFilterHeaderCollectionViewCell: BaseCollectionViewCell {

    class var reuseIdentifier: String {
        String(describing: self)
    }

    // MARK: - Types

    @MainActor
    struct TextPillStyle {
        let horizontalInset: CGFloat
        let cornerRadius: CGFloat
        let borderWidth: CGFloat
        let numberOfLines: Int
        let resetBorderColor: UIColor
        let unselectedBorderColor: UIColor

        static var filterHeader: TextPillStyle {
            TextPillStyle(
                horizontalInset: 16,
                cornerRadius: 18,
                borderWidth: 2,
                numberOfLines: 1,
                resetBorderColor: .clear,
                unselectedBorderColor: ThemeColor.highlight.withAlphaComponent(0.36)
            )
        }

        static var genrePageSheet: TextPillStyle {
            TextPillStyle(
                horizontalInset: 8,
                cornerRadius: 12,
                borderWidth: 2,
                numberOfLines: 2,
                resetBorderColor: ThemeColor.highlight.withAlphaComponent(0.36),
                unselectedBorderColor: ThemeColor.highlight.withAlphaComponent(0.36)
            )
        }
    }

    // MARK: - UI Components

    private var style = TextPillStyle.filterHeader

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    private var titleLeadingConstraint: Constraint?
    private var titleTrailingConstraint: Constraint?

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        contentView.isSkeletonable = true
        containerView.isSkeletonable = true
        applyTextPillStyle(style)
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            titleLeadingConstraint = make.leading.equalToSuperview().inset(style.horizontalInset).constraint
            titleTrailingConstraint = make.trailing.equalToSuperview().inset(style.horizontalInset).constraint
            make.centerY.equalToSuperview()
        }
    }

    override func resetForReuse() {
        hideSkeletonIfNeeded()
        titleLabel.isHidden = false
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = style.resetBorderColor.cgColor
    }

    // MARK: - Configuration

    func configureSkeleton() {
        titleLabel.isHidden = true
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = style.resetBorderColor.cgColor
        showSkeletonIfNeeded()
    }

    func configure(
        title: String,
        isSelected: Bool
    ) {
        hideSkeletonIfNeeded()
        titleLabel.isHidden = false
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .white : ThemeColor.textPrimary
        containerView.backgroundColor = isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        containerView.layer.borderColor = borderColor(isSelected: isSelected).cgColor
    }

    func applyTextPillStyle(_ style: TextPillStyle) {
        self.style = style
        titleLabel.numberOfLines = style.numberOfLines
        containerView.layer.cornerRadius = style.cornerRadius
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = style.borderWidth
        titleLeadingConstraint?.update(inset: style.horizontalInset)
        titleTrailingConstraint?.update(inset: style.horizontalInset)
    }

    // MARK: - Private Methods

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : style.unselectedBorderColor
    }

    private func showSkeletonIfNeeded() {
        guard !containerView.sk.isSkeletonActive else { return }
        containerView.showAnimatedGradientSkeleton()
    }

    private func hideSkeletonIfNeeded() {
        guard containerView.sk.isSkeletonActive else { return }
        containerView.hideSkeleton()
    }
}
