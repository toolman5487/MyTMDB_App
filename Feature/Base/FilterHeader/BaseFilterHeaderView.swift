//
//  BaseFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import SnapKit
import UIKit

// MARK: - BaseFilterHeaderView

@MainActor
class BaseFilterHeaderView: UICollectionReusableView {

    // MARK: - Properties

    private(set) var filters: [BaseFilterHeaderItem] = []
    private(set) var selectedFilterID: Int?
    private var isShowAllButtonExpanded = false
    private(set) var isShowingSkeleton = false
    var onFilterSelected: ((Int) -> Void)?
    var onShowAllFilters: (() -> Void)?

    // MARK: - Layout

    enum Layout {
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

    private(set) lazy var collectionView: UICollectionView = {
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
            BaseFilterHeaderCollectionViewCell.self,
            forCellWithReuseIdentifier: BaseFilterHeaderCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private(set) lazy var showAllButton: UIButton = {
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
        resetFilterState()
    }

    // MARK: - Setup

    func configureView() {
        backgroundColor = ThemeColor.background
    }

    func setupHierarchy() {
        addSubview(collectionView)
        addSubview(showAllButton)
    }

    func setupConstraints() {
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
        filters: [BaseFilterHeaderItem],
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
        scrollToSelectedFilterIfNeeded()
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

    func resetFilterState() {
        filters = []
        selectedFilterID = nil
        onFilterSelected = nil
        onShowAllFilters = nil
        isShowingSkeleton = false
        setShowAllButtonExpanded(false)
        collectionView.reloadData()
    }

    // MARK: - Sizing

    static func filterItemSize(for title: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let width = (title as NSString).size(withAttributes: [.font: font]).width
            + Layout.itemHorizontalInset * 2

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }

    static func skeletonItemSize(at index: Int) -> CGSize {
        let width = Layout.skeletonItemWidths[index % Layout.skeletonItemWidths.count]

        return CGSize(
            width: width,
            height: Layout.itemHeight
        )
    }

    // MARK: - Actions

    @objc private func handleShowAllButtonTapped() {
        guard !isShowingSkeleton else { return }
        onShowAllFilters?()
    }

    // MARK: - Private Methods

    private func scrollToSelectedFilterIfNeeded() {
        guard !isShowingSkeleton,
              let selectedIndex = filters.firstIndex(where: \.isSelected) else {
            return
        }

        collectionView.scrollToItem(
            at: IndexPath(item: selectedIndex, section: 0),
            at: .centeredHorizontally,
            animated: false
        )
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

// MARK: - UICollectionViewDataSource

extension BaseFilterHeaderView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isShowingSkeleton ? Layout.skeletonItemWidths.count : filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BaseFilterHeaderCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? BaseFilterHeaderCollectionViewCell {
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

extension BaseFilterHeaderView: UICollectionViewDelegateFlowLayout {

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
}
