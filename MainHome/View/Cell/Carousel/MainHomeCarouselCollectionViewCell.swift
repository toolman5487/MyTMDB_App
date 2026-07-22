//
//  MainHomeCarouselCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainHomeCarouselCollectionViewCell

@MainActor
final class MainHomeCarouselCollectionViewCell: BaseCollectionViewCell {

    // MARK: - Constants

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let bottomInset: CGFloat = 16
        static let textSpacing: CGFloat = 4
    }

    // MARK: - UI Components

    private let backdropImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let gradientView = MainHomeCarouselGradientView()

    private let statusLabel = AppFactory.Label.captionPrimary(color: ThemeColor.highlight, lines: 1)

    private let titleLabel = AppFactory.Label.title2(lines: 2)

    private let metadataLabel = AppFactory.Label.captionPrimary(color: ThemeColor.textSecondary, lines: 1)

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(backdropImageView)
        containerView.addSubview(gradientView)
        containerView.addSubview(statusLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(metadataLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backdropImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        gradientView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        metadataLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalToSuperview().inset(Layout.bottomInset)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalTo(metadataLabel.snp.top).offset(-Layout.textSpacing)
        }

        statusLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalTo(titleLabel.snp.top).offset(-Layout.textSpacing)
        }
    }

    override func resetForReuse() {
        backdropImageView.sd_cancelCurrentImageLoad()
        backdropImageView.image = nil
        statusLabel.text = nil
        titleLabel.text = nil
        metadataLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: MainHomeContentItem) {
        backdropImageView.image = nil

        if let backdropURL = item.backdropURL {
            backdropImageView.sd_setImage(with: backdropURL)
        } else if let posterURL = item.posterURL {
            backdropImageView.sd_setImage(with: posterURL)
        }

        statusLabel.text = "現正熱映"
        titleLabel.text = item.title
        metadataLabel.text = BaseDisplayTextFormatter.metadata([
            item.dateText,
            BaseDisplayTextFormatter.ratingText(item.scoreText)
        ])
    }
}

// MARK: - MainHomeCarouselGradientView

@MainActor
private final class MainHomeCarouselGradientView: UIView {

    override class var layerClass: AnyClass {
        CAGradientLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureGradient()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureGradient()
    }

    private func configureGradient() {
        guard let gradientLayer = layer as? CAGradientLayer else { return }
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            ThemeColor.background.withAlphaComponent(0.88).cgColor
        ]
        gradientLayer.locations = [0.35, 1]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
    }
}
