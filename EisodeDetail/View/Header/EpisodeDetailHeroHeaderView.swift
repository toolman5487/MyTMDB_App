//
//  EpisodeDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - EpisodeDetailHeroHeaderView

@MainActor
final class EpisodeDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: EpisodeDetailHeroHeaderView.self)
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

    private let episodeLabel = AppFactory.Label.subheadline(color: ThemeColor.highlight)

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

    func configure(with item: EpisodeDetailItem) {
        bannerImageView.sd_setImage(with: item.stillURL)
        posterImageView.sd_setImage(with: item.stillURL)
        titleLabel.text = item.title
        episodeLabel.text = "\(item.seasonNumberText) · \(item.episodeNumberText)"
        metadataLabel.text = metadataText(from: item)
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
        addSubview(episodeLabel)
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

        episodeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(episodeLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    private func metadataText(from item: EpisodeDetailItem) -> String {
        [item.airDateText, item.runtimeText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private func resetContent() {
        bannerImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        bannerImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        episodeLabel.text = nil
        metadataLabel.text = nil
        scoreLabel.text = nil
    }
}
