//
//  DetailContentListCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - DetailContentListRowCollectionViewCell

@MainActor
final class DetailContentListRowCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailContentListRowCollectionViewCell.self)

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let contentSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let portraitWidth: CGFloat = 64
        static let landscapeWidth: CGFloat = 144
        static let cornerRadius: CGFloat = 8
        static let chevronSize: CGFloat = 16
    }

    private var thumbnailWidthConstraint: Constraint?

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 2)
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    private let subtitleLabel = AppFactory.Label.captionSecondary(
        color: ThemeColor.textSecondary,
        lines: 2
    )

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = ThemeColor.textTertiary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(chevronImageView)
        containerView.addSubview(separatorView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Layout.verticalInset)
            thumbnailWidthConstraint = make.width.equalTo(Layout.portraitWidth).constraint
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.chevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(Layout.contentSpacing)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-Layout.contentSpacing)
            make.bottom.equalTo(containerView.snp.centerY).offset(-Layout.labelSpacing / 2)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(containerView.snp.centerY).offset(Layout.labelSpacing / 2)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    override func resetForReuse() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
        thumbnailWidthConstraint?.update(offset: Layout.portraitWidth)
    }

    func configure(
        with item: DetailContentListItem,
        thumbnailStyle: DetailContentListThumbnailStyle
    ) {
        thumbnailImageView.sd_setImage(with: item.imageURL)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true
        chevronImageView.isHidden = item.destination == .none

        switch thumbnailStyle {
        case .portrait:
            thumbnailWidthConstraint?.update(offset: Layout.portraitWidth)

        case .landscape:
            thumbnailWidthConstraint?.update(offset: Layout.landscapeWidth)

        case .gallery:
            break
        }
    }
}

// MARK: - DetailContentListGalleryCollectionViewCell

@MainActor
final class DetailContentListGalleryCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailContentListGalleryCollectionViewCell.self)

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let cornerRadius: CGFloat = 8
    }

    private let galleryImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        return imageView
    }()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(galleryImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        galleryImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Layout.verticalInset,
                    left: Layout.horizontalInset,
                    bottom: Layout.verticalInset,
                    right: Layout.horizontalInset
                )
            )
        }
    }

    override func resetForReuse() {
        galleryImageView.sd_cancelCurrentImageLoad()
        galleryImageView.image = nil
    }

    func configure(with item: DetailContentListItem) {
        galleryImageView.sd_setImage(with: item.imageURL)
    }
}
