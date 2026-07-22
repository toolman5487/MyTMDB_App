//
//  MainHomePosterCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SDWebImage
import SkeletonView
import SnapKit
import UIKit

// MARK: - MainHomePosterCollectionViewCell

@MainActor
final class MainHomePosterCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainHomePosterCollectionViewCell.self)

    private enum Layout {
        static let posterHeight: CGFloat = 186
        static let titleTopSpacing: CGFloat = 4
        static let scoreTopSpacing: CGFloat = 0
        static let posterCornerRadius: CGFloat = 8
    }

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = ThemeColor.textTertiary
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.posterCornerRadius
        imageView.isSkeletonable = true
        return imageView
    }()

    private let titleLabel = AppFactory.Label.captionPrimary(lines: 1)

    private let scoreLabel = AppFactory.Label.captionSecondary(color: ThemeColor.textSecondary, lines: 1)

    override func configureView() {
        contentView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(posterImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scoreLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        posterImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.posterHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(Layout.titleTopSpacing)
            make.leading.trailing.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.scoreTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        posterImageView.sd_cancelCurrentImageLoad()
        posterImageView.image = nil
        showPosterSkeletonIfNeeded()
        titleLabel.text = nil
        scoreLabel.text = nil
    }

    func configure(with item: MainHomeContentItem) {
        posterImageView.image = nil
        showPosterSkeletonIfNeeded()

        if let posterURL = item.posterURL {
            posterImageView.sd_setImage(with: posterURL) { [weak self] image, _, _, _ in
                guard let self else { return }

                if image == nil {
                    showPosterSkeletonIfNeeded()
                } else {
                    hidePosterSkeletonIfNeeded()
                }
            }
        }

        titleLabel.text = item.title
        scoreLabel.text = BaseDisplayTextFormatter.ratingText(item.scoreText)
    }

    private func showPosterSkeletonIfNeeded() {
        guard !posterImageView.sk.isSkeletonActive else { return }
        posterImageView.showAnimatedGradientSkeleton()
    }

    private func hidePosterSkeletonIfNeeded() {
        guard posterImageView.sk.isSkeletonActive else { return }
        posterImageView.hideSkeleton()
    }
}
