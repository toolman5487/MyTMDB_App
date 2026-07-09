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

    static let reuseIdentifier = String(describing: BaseFilterHeaderCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        contentView.isSkeletonable = true
        containerView.isSkeletonable = true
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 2
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: Layout.horizontalInset,
                    bottom: 0,
                    right: Layout.horizontalInset
                )
            )
        }
    }

    override func resetForReuse() {
        hideSkeletonIfNeeded()
        titleLabel.isHidden = false
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Configuration

    func configureSkeleton() {
        titleLabel.isHidden = true
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
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

    // MARK: - Private Methods

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
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
