//
//  DetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - DetailHeroHeaderContent

nonisolated struct DetailHeroHeaderContent: Sendable, Equatable {
    let title: String
    let originalTitle: String
    let tagline: String?
    let posterURL: URL?
    let backdropURL: URL?
    let scoreText: String?
    let voteCountText: String?
    let metadataText: String?

    var displayTitle: String {
        title.isEmpty ? originalTitle : title
    }

    var scoreDisplayText: String? {
        guard let scoreText, let voteCountText else { return nil }
        return "評分 \(scoreText) (\(voteCountText))"
    }
}

// MARK: - DetailHeroHeaderView

@MainActor
class DetailHeroHeaderView: UICollectionReusableView {

    private enum Layout {
        static let backdropHeight: CGFloat = 220
        static let posterWidth: CGFloat = 112
        static let posterHeight: CGFloat = 168
        static let contentHorizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 16
        static let taglineTopSpacing: CGFloat = 8
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
        let label = AppFactory.Label.title2(lines: 1)
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 24, weight: .bold)
        )
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }()

    private let taglineLabel = AppFactory.Label.callout(color: ThemeColor.highlight, lines: 2)

    private let metadataLabel = AppFactory.Label.captionPrimary(color: ThemeColor.textSecondary, lines: 1)

    private let scoreLabel = AppFactory.Label.headline()

    private var taglineTopConstraint: Constraint?
    private var taglineHeightConstraint: Constraint?

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

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let attributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        let targetWidth = layoutAttributes.size.width
        guard targetWidth > 0 else { return attributes }

        let targetSize = CGSize(
            width: targetWidth,
            height: UIView.layoutFittingCompressedSize.height
        )
        let size = systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        attributes.size = CGSize(width: targetWidth, height: ceil(size.height))
        return attributes
    }

    final func configure(with content: DetailHeroHeaderContent) {
        backdropImageView.sd_setImage(with: content.backdropURL)
        posterImageView.sd_setImage(with: content.posterURL)
        titleLabel.text = content.displayTitle

        let tagline = content.tagline?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasTagline = tagline?.isEmpty == false
        taglineLabel.text = hasTagline ? tagline : nil
        updateTaglineVisibility(isVisible: hasTagline)

        metadataLabel.text = content.metadataText
        metadataLabel.isHidden = content.metadataText?.isEmpty != false

        if let scoreDisplayText = content.scoreDisplayText {
            scoreLabel.text = scoreDisplayText
            scoreLabel.isHidden = false
        } else {
            scoreLabel.text = nil
            scoreLabel.isHidden = true
        }
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
            make.leading.equalToSuperview().offset(Layout.contentHorizontalInset)
            make.top.equalTo(backdropImageView.snp.bottom).offset(-72)
            make.width.equalTo(Layout.posterWidth)
            make.height.equalTo(Layout.posterHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backdropImageView.snp.bottom).offset(16)
            make.leading.equalTo(posterImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(Layout.contentHorizontalInset)
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        taglineLabel.snp.makeConstraints { make in
            taglineTopConstraint = make.top.equalTo(posterImageView.snp.bottom)
                .offset(Layout.taglineTopSpacing)
                .constraint
            make.leading.trailing.equalToSuperview().inset(Layout.contentHorizontalInset)
            make.bottom.equalToSuperview().inset(Layout.bottomInset)
            taglineHeightConstraint = make.height.equalTo(0).constraint
        }
        taglineHeightConstraint?.deactivate()
    }

    private func resetContent() {
        backdropImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        backdropImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        taglineLabel.text = nil
        metadataLabel.text = nil
        metadataLabel.isHidden = false
        scoreLabel.text = nil
        scoreLabel.isHidden = false
        updateTaglineVisibility(isVisible: false)
    }

    private func updateTaglineVisibility(isVisible: Bool) {
        taglineLabel.isHidden = !isVisible
        taglineTopConstraint?.update(offset: isVisible ? Layout.taglineTopSpacing : 0)

        if isVisible {
            taglineHeightConstraint?.deactivate()
        } else {
            taglineHeightConstraint?.activate()
        }
    }
}
