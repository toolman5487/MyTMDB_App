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

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHeight: CGFloat = 44
    }

    // MARK: - UI Components

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
        collectionView.dragInteractionEnabled = false
        collectionView.register(
            MainSearchHistoryPillCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchHistoryPillCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Properties

    private var entries: [SearchHistoryEntry] = []
    private var onKeywordSelected: ((String) -> Void)?
    private var onKeywordDeleted: ((SearchHistoryEntry) -> Void)?
    private var onEntryMoved: ((SearchHistoryEntry, Int) -> Void)?

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        containerView.backgroundColor = .clear
        collectionView.addGestureRecognizer(
            UILongPressGestureRecognizer(target: self, action: #selector(handleReorderGesture(_:)))
        )
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
        onKeywordDeleted = nil
        onEntryMoved = nil
        collectionView.reloadData()
    }

    // MARK: - Configuration

    static func preferredHeight(entryCount: Int) -> CGFloat {
        guard entryCount > 0 else { return 0 }
        return Layout.itemHeight
    }

    func configure(
        entries: [SearchHistoryEntry],
        onKeywordSelected: @escaping (String) -> Void,
        onKeywordDeleted: @escaping (SearchHistoryEntry) -> Void,
        onEntryMoved: @escaping (SearchHistoryEntry, Int) -> Void
    ) {
        self.entries = entries
        self.onKeywordSelected = onKeywordSelected
        self.onKeywordDeleted = onKeywordDeleted
        self.onEntryMoved = onEntryMoved
        collectionView.reloadData()
    }

    // MARK: - Actions

    @objc private func handleReorderGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let location = gestureRecognizer.location(in: collectionView)

        switch gestureRecognizer.state {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: location) else { return }
            collectionView.beginInteractiveMovementForItem(at: indexPath)

        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(location)

        case .ended:
            collectionView.endInteractiveMovement()

        default:
            collectionView.cancelInteractiveMovement()
        }
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
            let entry = entries[indexPath.item]
            cell.configure(with: entry) { [weak self] entry in
                self?.onKeywordDeleted?(entry)
            }
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        entries.indices.contains(indexPath.item)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        guard entries.indices.contains(sourceIndexPath.item) else {
            collectionView.reloadData()
            return
        }

        let movedEntry = entries.remove(at: sourceIndexPath.item)
        let boundedDestinationIndex = min(max(0, destinationIndexPath.item), entries.count)
        entries.insert(movedEntry, at: boundedDestinationIndex)
        onEntryMoved?(movedEntry, boundedDestinationIndex)
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
        return MainSearchHistoryPillCollectionViewCell.preferredSize(for: entries[indexPath.item].keyword)
    }
}

// MARK: - MainSearchHistoryPillCollectionViewCell

@MainActor
final class MainSearchHistoryPillCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchHistoryPillCollectionViewCell.self)

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let deleteButtonWidth: CGFloat = 44
        static let itemHeight: CGFloat = 44
        static let cornerRadius: CGFloat = 20
        static let borderWidth: CGFloat = 1
    }

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.subheadline(alignment: .center)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private lazy var deleteButton: UIButton = {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "xmark.circle.fill")
        configuration.baseForegroundColor = ThemeColor.highlight
        configuration.contentInsets = .zero
        button.configuration = configuration
        button.isAccessibilityElement = false
        button.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Properties

    private var entry: SearchHistoryEntry?
    private var onDeleteRequested: ((SearchHistoryEntry) -> Void)?

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.backgroundColor = ThemeColor.primary
        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.borderWidth = Layout.borderWidth
        containerView.layer.borderColor = ThemeColor.highlight.cgColor
        containerView.layer.masksToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
        containerView.addSubview(deleteButton)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.trailing.equalTo(deleteButton.snp.leading)
            make.top.bottom.equalToSuperview()
        }

        deleteButton.snp.makeConstraints { make in
            make.top.trailing.bottom.equalToSuperview()
            make.width.equalTo(Layout.deleteButtonWidth)
        }
    }

    override func resetForReuse() {
        super.resetForReuse()
        titleLabel.text = nil
        entry = nil
        onDeleteRequested = nil
        accessibilityCustomActions = nil
    }

    // MARK: - Configuration

    static func preferredSize(for keyword: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let titleWidth = (keyword as NSString).size(withAttributes: [.font: font]).width
        let width = Layout.horizontalInset + titleWidth + Layout.deleteButtonWidth

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }

    func configure(
        with entry: SearchHistoryEntry,
        onDeleteRequested: @escaping (SearchHistoryEntry) -> Void
    ) {
        self.entry = entry
        self.onDeleteRequested = onDeleteRequested
        titleLabel.text = entry.keyword
        applyAccessibility(
            AccessibilityText(
                label: "最近搜尋：\(entry.keyword)",
                hint: "點兩下以再次搜尋，長按可拖曳排序"
            )
        )
        accessibilityTraits = .button
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(
                name: "刪除",
                target: self,
                selector: #selector(deleteAccessibilityAction(_:))
            )
        ]
    }

    // MARK: - Actions

    @objc private func deleteButtonTapped() {
        guard let entry else { return }
        onDeleteRequested?(entry)
    }

    @objc private func deleteAccessibilityAction(_ action: UIAccessibilityCustomAction) -> Bool {
        guard let entry else { return false }
        onDeleteRequested?(entry)
        return true
    }
}

// MARK: - MainSearchPopularPeopleCollectionViewCell

@MainActor
final class MainSearchPopularPeopleCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainSearchResultItem,
    MainSearchPopularPersonCollectionViewCell
> {

    static let reuseIdentifier = String(describing: MainSearchPopularPeopleCollectionViewCell.self)

    // MARK: - Constants

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

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainSearchPopularPersonCollectionViewCell.self,
            reuseIdentifier: MainSearchPopularPersonCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(width: Layout.itemWidth, height: Layout.itemHeight)
        )
    }

    // MARK: - Configuration

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

    // MARK: - Constants

    private enum Layout {
        static let avatarSize: CGFloat = 72
        static let titleTopSpacing: CGFloat = 4
    }

    // MARK: - UI Components

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
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    // MARK: - BaseCollectionViewCell

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

    // MARK: - Configuration

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

    // MARK: - Configuration

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
