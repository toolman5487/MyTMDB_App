//
//  MainSearchIdleCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSearchRecentHistoryCollectionViewCell

@MainActor
final class MainSearchRecentHistoryCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchRecentHistoryCollectionViewCell.self)

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHeight: CGFloat = 36
    }

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Layout.horizontalInset,
            bottom: 0,
            right: Layout.horizontalInset
        )
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.delaysContentTouches = false
        collectionView.decelerationRate = .fast
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainSearchHistoryPillCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchHistoryPillCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private var entries: [SearchHistoryEntry] = []
    private var onKeywordSelected: ((String) -> Void)?

    static func preferredHeight(entryCount: Int) -> CGFloat {
        guard entryCount > 0 else { return 0 }
        return Layout.itemHeight
    }

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func resetForReuse() {
        entries = []
        onKeywordSelected = nil
        collectionView.reloadData()
    }

    func configure(
        entries: [SearchHistoryEntry],
        onKeywordSelected: @escaping (String) -> Void
    ) {
        self.entries = entries
        self.onKeywordSelected = onKeywordSelected
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainSearchRecentHistoryCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        entries.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainSearchHistoryPillCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainSearchHistoryPillCollectionViewCell,
           entries.indices.contains(indexPath.item) {
            cell.configure(with: entries[indexPath.item])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainSearchRecentHistoryCollectionViewCell: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard entries.indices.contains(indexPath.item) else { return }
        onKeywordSelected?(entries[indexPath.item].keyword)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard entries.indices.contains(indexPath.item) else { return .zero }
        return BaseFilterHeaderView.filterItemSize(for: entries[indexPath.item].keyword)
    }
}

// MARK: - MainSearchHistoryPillCollectionViewCell

@MainActor
final class MainSearchHistoryPillCollectionViewCell: BaseFilterHeaderCollectionViewCell {

    // MARK: - Configuration

    func configure(with entry: SearchHistoryEntry) {
        configure(
            title: entry.keyword,
            isSelected: true
        )
        applyAccessibility(
            AccessibilityText(
                label: "最近搜尋：\(entry.keyword)",
                hint: "點兩下以再次搜尋"
            )
        )
        accessibilityTraits = .button
    }
}

// MARK: - MainSearchPopularPeopleCollectionViewCell

@MainActor
final class MainSearchPopularPeopleCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainSearchResultItem,
    MainSearchPopularPersonCollectionViewCell
> {

    static let reuseIdentifier = String(describing: MainSearchPopularPeopleCollectionViewCell.self)

    private enum Layout {
        static let itemWidth: CGFloat = 88
        static let avatarSize: CGFloat = 72
        static let titleTopSpacing: CGFloat = 4
        private static let minimumItemHeight: CGFloat = 112

        static var itemHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            return max(
                minimumItemHeight,
                avatarSize + titleTopSpacing + titleHeight
            )
        }
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
        updateItemSize(
            CGSize(
                width: Layout.itemWidth,
                height: Layout.itemHeight
            )
        )
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

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(alignment: .center, lines: 1)
        label.adjustsFontSizeToFitWidth = true
        label.allowsDefaultTighteningForTruncation = true
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        avatarImageView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
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
        applyAccessibility(person.accessibilityText)
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
                imageHeight: imageHeight,
                accessibilityText: item.accessibilityText
            )
        )
    }
}
