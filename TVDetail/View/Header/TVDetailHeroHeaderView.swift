//
//  TVDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - TVDetailHeroHeaderView

@MainActor
final class TVDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailHeroHeaderView.self)

    enum TaglinePresentation: Equatable {
        case none
        case singleLine
        case doubleLine

        var headerHeight: CGFloat {
            switch self {
            case .none:
                return 356

            case .singleLine:
                return 376

            case .doubleLine:
                return 388
            }
        }
    }

    private enum Layout {
        static let backdropHeight: CGFloat = 220
        static let posterWidth: CGFloat = 112
        static let posterHeight: CGFloat = 168
        static let contentHorizontalInset: CGFloat = 16
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

    func configure(with item: TVDetailHeroItem) {
        backdropImageView.sd_setImage(with: item.backdropURL)
        posterImageView.sd_setImage(with: item.posterURL)
        titleLabel.text = item.title.isEmpty ? item.originalTitle : item.title

        let tagline = item.tagline?.trimmingCharacters(in: .whitespacesAndNewlines)
        taglineLabel.text = tagline
        taglineLabel.isHidden = tagline?.isEmpty != false

        metadataLabel.text = item.metadataText
        metadataLabel.isHidden = item.metadataText?.isEmpty != false

        if let scoreText = item.scoreText,
           let voteCountText = item.voteCountText {
            scoreLabel.text = "評分 \(scoreText) (\(voteCountText))"
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
            make.top.equalTo(posterImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(Layout.contentHorizontalInset)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    private func resetContent() {
        backdropImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        backdropImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        taglineLabel.text = nil
        taglineLabel.isHidden = false
        metadataLabel.text = nil
        metadataLabel.isHidden = false
        scoreLabel.text = nil
        scoreLabel.isHidden = false
    }
}

// MARK: - Layout Calculation

extension TVDetailHeroHeaderView {

    static func headerHeight(for item: TVDetailHeroItem, width: CGFloat) -> CGFloat {
        taglinePresentation(for: item.tagline, width: width).headerHeight
    }

    static func taglinePresentation(
        for tagline: String?,
        width: CGFloat
    ) -> TaglinePresentation {
        let trimmedTagline = tagline?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmedTagline, !trimmedTagline.isEmpty else {
            return .none
        }

        let availableWidth = width - (Layout.contentHorizontalInset * 2)
        guard availableWidth > 0 else {
            return .singleLine
        }

        let font = UIFont.preferredFont(forTextStyle: .callout)
        let boundingRect = (trimmedTagline as NSString).boundingRect(
            with: CGSize(width: availableWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )

        return boundingRect.height <= font.lineHeight * 1.2 ? .singleLine : .doubleLine
    }
}
