//
//  MovieDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MovieDetailHeroHeaderView

@MainActor
final class MovieDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MovieDetailHeroHeaderView.self)

    private enum Layout {
        static let backdropHeight: CGFloat = 220
        static let posterWidth: CGFloat = 112
        static let posterHeight: CGFloat = 168
    }

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()

    private let backdropImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
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
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 24, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let originalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.highlight
        label.numberOfLines = 2
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

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

    private func configureView() {
        backgroundColor = .clear
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = false
    }

    private func setupHierarchy() {
        addSubview(containerView)
        containerView.addSubview(backdropImageView)
        containerView.addSubview(posterImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(originalTitleLabel)
        containerView.addSubview(taglineLabel)
        containerView.addSubview(metadataLabel)
        containerView.addSubview(scoreLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backdropImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.backdropHeight)
        }

        posterImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(backdropImageView.snp.bottom).offset(-72)
            make.width.equalTo(Layout.posterWidth)
            make.height.equalTo(Layout.posterHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backdropImageView.snp.bottom).offset(16)
            make.leading.equalTo(posterImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        originalTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(originalTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(scoreLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    private func resetContent() {
        backdropImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        backdropImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        originalTitleLabel.text = nil
        taglineLabel.text = nil
        metadataLabel.text = nil
        scoreLabel.text = nil
    }

    func configure(with item: MovieDetailHeroItem) {
        backdropImageView.sd_setImage(with: item.backdropURL)
        posterImageView.sd_setImage(with: item.posterURL)
        titleLabel.text = item.title
        originalTitleLabel.text = item.originalTitle == item.title ? nil : item.originalTitle
        taglineLabel.text = item.tagline
        metadataLabel.text = item.metadataText
        scoreLabel.text = "評分 \(item.scoreText) (\(item.voteCountText))"
    }
}
