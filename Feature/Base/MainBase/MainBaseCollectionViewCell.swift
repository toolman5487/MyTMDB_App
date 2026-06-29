//
//  MainBaseCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SkeletonView
import SnapKit
import UIKit

// MARK: - MainBaseCollectionViewCell

@MainActor
class MainBaseCollectionViewCell: UICollectionViewCell {

    // MARK: - Properties

    class var reuseIdentifier: String {
        String(describing: self)
    }

    var skeletonContainerView: UIView {
        contentView
    }

    var skeletonGradient: SkeletonGradient {
        SkeletonGradient(
            baseColor: ThemeColor.fillSecondary,
            secondaryColor: ThemeColor.fill
        )
    }

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
        bindViewModel()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
        bindViewModel()
    }

    // MARK: - Template Methods

    func configureView() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        skeletonContainerView.isSkeletonable = true
    }

    func setupHierarchy() {}

    func setupConstraints() {}

    func bindViewModel() {}

    func resetContent() {}

    func skeletonableSubviews() -> [UIView] {
        []
    }

    // MARK: - Skeleton

    func configureSkeletonAppearance() {
        skeletonableSubviews().forEach { view in
            view.isSkeletonable = true
        }
    }

    func showSkeletonAnimation(
        transition: SkeletonTransitionStyle = .crossDissolve(0.25)
    ) {
        configureSkeletonAppearance()
        skeletonContainerView.showAnimatedGradientSkeleton(
            usingGradient: skeletonGradient,
            transition: transition
        )
    }

    func hideSkeletonAnimation(
        transition: SkeletonTransitionStyle = .crossDissolve(0.25)
    ) {
        skeletonContainerView.hideSkeleton(transition: transition)
    }

    // MARK: - Reuse

    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeletonAnimation(transition: .none)
        resetContent()
    }

    // MARK: - Layout

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetSize = CGSize(
            width: layoutAttributes.size.width,
            height: UIView.layoutFittingCompressedSize.height
        )
        let fittedSize = contentView.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attributes.size.height = ceil(fittedSize.height)
        return attributes
    }
}
