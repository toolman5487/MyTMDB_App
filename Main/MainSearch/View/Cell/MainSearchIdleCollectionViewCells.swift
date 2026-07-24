//
//  MainSearchIdleCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSearchPopularPeopleCollectionViewCell

@MainActor
final class MainSearchPopularPeopleCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainSearchResultItem,
    MainSearchPopularPersonCollectionViewCell
> {

    static let reuseIdentifier = String(describing: MainSearchPopularPeopleCollectionViewCell.self)

    private enum Layout {
        static let itemWidth: CGFloat = 88
        static let itemHeight: CGFloat = 112
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainSearchPopularPersonCollectionViewCell.self,
            reuseIdentifier: MainSearchPopularPersonCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        )
    }

    func configure(
        people: [MainSearchResultItem],
        onPersonSelected: @escaping (MainSearchResultItem) -> Void
    ) {
        configureItems(
            people,
            onItemSelected: onPersonSelected
        ) { cell, person in
            cell.configure(with: person)
        }
    }
}

// MARK: - MainSearchPopularPersonCollectionViewCell

@MainActor
final class MainSearchPopularPersonCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchPopularPersonCollectionViewCell.self)

    private enum Layout {
        static let avatarSize: CGFloat = 72
        static let titleTopSpacing: CGFloat = 4
    }

    private let avatarImageView: UIImageView = {
        let imageView = AppFactory.ImageView.avatar(size: Layout.avatarSize)
        imageView.contentMode = .scaleAspectFill
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = ThemeColor.highlight.cgColor
        imageView.image = nil
        return imageView
    }()

    private let titleLabel = AppFactory.Label.captionPrimary(alignment: .center, lines: 1)

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(avatarImageView)
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        avatarImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(Layout.avatarSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(Layout.titleTopSpacing)
            make.leading.trailing.equalToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func resetForReuse() {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil
        titleLabel.text = nil
    }

    func configure(with person: MainSearchResultItem) {
        avatarImageView.sd_setImage(with: person.imageURL)
        titleLabel.text = person.title
    }
}

// MARK: - MainSearchTrendingCollectionViewCell

@MainActor
final class MainSearchTrendingCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchTrendingCollectionViewCell.self)

    func configure(
        with item: MainSearchResultItem,
        imageHeight: CGFloat
    ) {
        configure(
            with: ImageTitleCellContent(
                imageURL: item.imageURL,
                title: item.title,
                subtitle: item.subtitle,
                imageHeight: imageHeight
            )
        )
    }
}
