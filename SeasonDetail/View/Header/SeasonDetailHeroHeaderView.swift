//
//  SeasonDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - SeasonDetailHeroHeaderView

@MainActor
final class SeasonDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: SeasonDetailHeroHeaderView.self)
    static let headerHeight: CGFloat = 292

    private enum Layout {
        static let bannerHeight: CGFloat = 148
        static let posterWidth: CGFloat = 112
        static let posterHeight: CGFloat = 168
        static let contentHorizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
    }

    private let bannerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.backgroundSecondary
        return view
    }()

    private let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.backgroundSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let bannerBlurView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        let view = UIVisualEffectView(effect: effect)
        return view
    }()

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.title2(lines: 2)
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 24, weight: .bold)
        )
        return label
    }()

    private let seasonLabel = AppFactory.Label.subheadline(color: ThemeColor.highlight)

    private let metadataLabel = AppFactory.Label.captionPrimary(color: ThemeColor.textSecondary, lines: 2)

    private let scoreLabel = AppFactory.Label.headline()

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
        resetContent()
    }

    func configure(with item: SeasonDetailItem) {
        bannerImageView.sd_setImage(with: item.posterURL)
        posterImageView.sd_setImage(with: item.posterURL)
        titleLabel.text = item.title
        seasonLabel.text = item.seasonNumberText
        metadataLabel.text = "\(item.airDateText) · \(item.episodeCountText)"
        scoreLabel.text = "評分 \(item.scoreText)"
    }

    private func configureView() {
        backgroundColor = .clear
    }

    private func setupHierarchy() {
        addSubview(bannerView)
        bannerView.addSubview(bannerImageView)
        bannerView.addSubview(bannerBlurView)
        addSubview(posterImageView)
        addSubview(titleLabel)
        addSubview(seasonLabel)
        addSubview(metadataLabel)
        addSubview(scoreLabel)
    }

    private func setupConstraints() {
        bannerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.bannerHeight)
        }

        bannerImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bannerBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        posterImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(Layout.contentHorizontalInset)
            make.bottom.equalTo(scoreLabel.snp.bottom)
            make.width.equalTo(Layout.posterWidth)
            make.height.equalTo(Layout.posterHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom).offset(Layout.itemSpacing)
            make.leading.equalTo(posterImageView.snp.trailing).offset(Layout.contentHorizontalInset)
            make.trailing.equalToSuperview().inset(Layout.contentHorizontalInset)
        }

        seasonLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(seasonLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    private func resetContent() {
        bannerImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        bannerImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        seasonLabel.text = nil
        metadataLabel.text = nil
        scoreLabel.text = nil
    }
}
