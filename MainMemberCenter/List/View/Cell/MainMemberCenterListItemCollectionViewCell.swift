//
//  MainMemberCenterListItemCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainMemberCenterListItemCollectionViewCell

@MainActor
final class MainMemberCenterListItemCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberCenterListItemCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let titleTopSpacing: CGFloat = 4
        static let metadataTopSpacing: CGFloat = 0
        static let posterCornerRadius: CGFloat = 8
        static let posterAspectRatio: CGFloat = 1.5
    }

    // MARK: - UI Components

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.tintColor = ThemeColor.textTertiary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = AppFactory.Label.captionSecondary(color: ThemeColor.textSecondary, lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        posterImageView.layer.cornerRadius = Layout.posterCornerRadius
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(posterImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(metadataLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        posterImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(posterImageView.snp.width).multipliedBy(Layout.posterAspectRatio)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(Layout.titleTopSpacing)
            make.leading.trailing.equalToSuperview()
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.metadataTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        posterImageView.sd_cancelCurrentImageLoad()
        posterImageView.image = nil
        titleLabel.text = nil
        metadataLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: MainMemberCenterListItem) {
        posterImageView.image = nil
        posterImageView.sd_setImage(
            with: item.imageURL,
            placeholderImage: UIImage(systemName: "photo")
        )
        titleLabel.text = item.title
        metadataLabel.text = item.metadataText
    }
}
