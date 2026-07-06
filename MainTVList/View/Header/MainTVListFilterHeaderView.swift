//
//  MainTVListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SkeletonView
import SnapKit
import UIKit

// MARK: - MainTVListFilterHeaderView

@MainActor
final class MainTVListFilterHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MainTVListFilterHeaderView.self)

    // MARK: - Properties

    private var filters: [MainTVGenreItem] = []
    private var selectedFilterID: Int?
    private var isShowAllButtonExpanded = false
    private var isShowingSkeleton = false
    var onFilterSelected: ((Int) -> Void)?
    var onShowAllFilters: (() -> Void)?

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHorizontalInset: CGFloat = 16
        static let itemHeight: CGFloat = 36
        static let buttonSize: CGFloat = 36
        static let buttonCollectionSpacing: CGFloat = 8
        static let skeletonItemWidths: [CGFloat] = [72, 96, 80, 104, 88]
        static let showAllButtonExpandedRotation = -CGFloat.pi / 2
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
        collectionView.register(
            MainTVListFilterCollectionViewCell.self,
            forCellWithReuseIdentifier: MainTVListFilterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var showAllButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.forward")
        configuration.baseForegroundColor = ThemeColor.textPrimary
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(handleShowAllButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

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
        filters = []
        selectedFilterID = nil
        onFilterSelected = nil
        onShowAllFilters = nil
        isShowingSkeleton = false
        setShowAllButtonExpanded(false)
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = ThemeColor.background
    }

    private func setupHierarchy() {
        addSubview(collectionView)
        addSubview(showAllButton)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(showAllButton.snp.leading).offset(-Layout.buttonCollectionSpacing)
        }

        showAllButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.size.equalTo(Layout.buttonSize)
        }
    }

    // MARK: - Configuration

    func configure(
        filters: [MainTVGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        self.filters = filters
        selectedFilterID = filters.first(where: \.isSelected)?.id
        self.isShowingSkeleton = isShowingSkeleton
        showAllButton.isHidden = isShowingSkeleton
        showAllButton.isEnabled = !isShowingSkeleton
        collectionView.isUserInteractionEnabled = !isShowingSkeleton
        setShowAllButtonExpanded(isExpanded)
        collectionView.reloadData()

        if !isShowingSkeleton,
           let selectedIndex = filters.firstIndex(where: \.isSelected) {
            collectionView.scrollToItem(
                at: IndexPath(item: selectedIndex, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }
    }

    func setShowAllButtonExpanded(_ isExpanded: Bool, animated: Bool = false) {
        let didChange = isShowAllButtonExpanded != isExpanded
        isShowAllButtonExpanded = isExpanded

        let transform: CGAffineTransform = isExpanded
            ? CGAffineTransform(rotationAngle: Layout.showAllButtonExpandedRotation)
            : .identity

        let updateTransform: () -> Void = { [weak self] in
            self?.showAllButton.imageView?.transform = transform
        }

        guard animated, didChange else {
            updateTransform()
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: updateTransform
        )
    }

    private static func filterItemSize(for title: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let width = (title as NSString).size(withAttributes: [.font: font]).width
            + Layout.itemHorizontalInset * 2

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }

    private static func skeletonItemSize(at index: Int) -> CGSize {
        let width = Layout.skeletonItemWidths[index % Layout.skeletonItemWidths.count]

        return CGSize(
            width: width,
            height: Layout.itemHeight
        )
    }

    @objc private func handleShowAllButtonTapped() {
        guard !isShowingSkeleton else { return }
        onShowAllFilters?()
    }
}

// MARK: - UICollectionViewDataSource

extension MainTVListFilterHeaderView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isShowingSkeleton ? Layout.skeletonItemWidths.count : filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainTVListFilterCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainTVListFilterCollectionViewCell {
            if isShowingSkeleton {
                cell.configureSkeleton()
            } else {
                let item = filters[indexPath.item]
                cell.configure(
                    title: item.name,
                    isSelected: item.id == selectedFilterID
                )
            }
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainTVListFilterHeaderView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !isShowingSkeleton,
              filters.indices.contains(indexPath.item) else {
            return
        }

        let selectedID = filters[indexPath.item].id
        guard selectedID != selectedFilterID else { return }

        updateSelectedFilter(id: selectedID, at: indexPath)
        onFilterSelected?(selectedID)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        if isShowingSkeleton {
            return Self.skeletonItemSize(at: indexPath.item)
        }

        return Self.filterItemSize(for: filters[indexPath.item].name)
    }

    private func updateSelectedFilter(id: Int, at indexPath: IndexPath) {
        let previousSelectedID = selectedFilterID
        selectedFilterID = id

        var indexPathsToReload = [indexPath]
        if let previousSelectedIndex = filters.firstIndex(where: { $0.id == previousSelectedID }),
           previousSelectedIndex != indexPath.item {
            indexPathsToReload.append(IndexPath(item: previousSelectedIndex, section: indexPath.section))
        }

        collectionView.reloadItems(at: indexPathsToReload)
    }
}

// MARK: - MainTVListFilterCollectionViewCell

@MainActor
private final class MainTVListFilterCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainTVListFilterCollectionViewCell.self)

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        contentView.isSkeletonable = true
        containerView.isSkeletonable = true
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 2
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: 16,
                    bottom: 0,
                    right: 16
                )
            )
        }
    }

    override func resetForReuse() {
        hideSkeletonIfNeeded()
        titleLabel.isHidden = false
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Configuration

    func configureSkeleton() {
        titleLabel.isHidden = true
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
        showSkeletonIfNeeded()
    }

    func configure(
        title: String,
        isSelected: Bool
    ) {
        hideSkeletonIfNeeded()
        titleLabel.isHidden = false
        titleLabel.text = title
        titleLabel.textColor = isSelected ? .white : ThemeColor.textPrimary
        containerView.backgroundColor = isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        containerView.layer.borderColor = borderColor(isSelected: isSelected).cgColor
    }

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
    }

    private func showSkeletonIfNeeded() {
        guard !containerView.sk.isSkeletonActive else { return }
        containerView.showAnimatedGradientSkeleton()
    }

    private func hideSkeletonIfNeeded() {
        guard containerView.sk.isSkeletonActive else { return }
        containerView.hideSkeleton()
    }
}
