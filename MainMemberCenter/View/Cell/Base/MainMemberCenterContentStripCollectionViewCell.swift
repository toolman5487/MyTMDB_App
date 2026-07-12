//
//  MainMemberCenterContentStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainMemberCenterContentStripCollectionViewCell

@MainActor
class MainMemberCenterContentStripCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainMemberCenterListItem,
    MainMemberCenterListItemCollectionViewCell
> {

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainMemberCenterListItemCollectionViewCell.self,
            reuseIdentifier: MainMemberCenterListItemCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(
                width: Layout.posterWidth,
                height: Layout.itemHeight
            )
        )
    }

    func configure(
        items: [MainMemberCenterListItem],
        onItemSelected: @escaping (MainMemberCenterListItem) -> Void
    ) {
        configureItems(
            items,
            onItemSelected: onItemSelected
        ) { cell, item in
            cell.configure(with: item)
        }
    }
}

// MARK: - MainMemberCenterListStripCollectionViewCell

@MainActor
class MainMemberCenterListStripCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainMemberCenterListItem,
    MainMemberCenterPlaylistCollectionViewCell
> {

    private enum Layout {
        static let itemWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainMemberCenterPlaylistCollectionViewCell.self,
            reuseIdentifier: MainMemberCenterPlaylistCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(
                width: Layout.itemWidth,
                height: Layout.itemHeight
            )
        )
    }

    func configure(
        items: [MainMemberCenterListItem],
        onItemSelected: @escaping (MainMemberCenterListItem) -> Void
    ) {
        configureItems(
            items,
            onItemSelected: onItemSelected
        ) { cell, item in
            cell.configure(with: item)
        }
    }
}

// MARK: - MainMemberCenterPlaylistCollectionViewCell

@MainActor
final class MainMemberCenterPlaylistCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberCenterPlaylistCollectionViewCell.self)

    private enum Layout {
        static let folderHeight: CGFloat = 186
        static let folderCornerRadius: CGFloat = 8
        static let iconPointSize: CGFloat = 32
        static let titleTopSpacing: CGFloat = 4
        static let countTopSpacing: CGFloat = 0
        static let borderWidth: CGFloat = 1
    }

    private let thumbnailContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.backgroundSecondary
        view.layer.cornerRadius = Layout.folderCornerRadius
        view.layer.borderColor = ThemeColor.separator.cgColor
        view.layer.borderWidth = Layout.borderWidth
        view.clipsToBounds = true
        return view
    }()

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let placeholderIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "play.rectangle.fill"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.highlight
        return imageView
    }()

    private let countBadgeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        containerView.clipsToBounds = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(thumbnailContainerView)
        thumbnailContainerView.addSubview(thumbnailImageView)
        thumbnailContainerView.addSubview(placeholderIconView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(countBadgeLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        thumbnailContainerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.folderHeight)
        }

        thumbnailImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        placeholderIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.iconPointSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailContainerView.snp.bottom).offset(Layout.titleTopSpacing)
            make.leading.trailing.equalToSuperview()
        }

        countBadgeLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.countTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        thumbnailImageView.image = nil
        placeholderIconView.isHidden = false
        countBadgeLabel.text = nil
        titleLabel.text = nil
    }

    func configure(with item: MainMemberCenterListItem) {
        if let imageURL = item.imageURL {
            placeholderIconView.isHidden = true
            thumbnailImageView.sd_setImage(with: imageURL) { [weak self] image, _, _, _ in
                self?.placeholderIconView.isHidden = image != nil
            }
        } else {
            thumbnailImageView.image = nil
            placeholderIconView.isHidden = false
        }

        countBadgeLabel.text = item.metadataText
        titleLabel.text = item.title
    }
}
