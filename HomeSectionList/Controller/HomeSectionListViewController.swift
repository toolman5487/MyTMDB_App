//
//  HomeSectionListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/9.
//

import Observation
import UIKit

// MARK: - HomeSectionListViewController

@MainActor
final class HomeSectionListViewController: BaseListViewController {

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let category: MainHomeContentCategory
    private let viewModel: HomeSectionListViewModel
    private lazy var router: HomeSectionListRouting = HomeSectionListRouter(sourceViewController: self)
    private var filters: [HomeSectionListGenreItem] = []
    private var items: [MainHomeContentItem] = []
    private var isFilterSkeletonVisible = true
    private var isFilterPageSheetPresented = false
    private var loadTask: Task<Void, Never>?
    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - Initialization

    init(category: MainHomeContentCategory) {
        self.category = category
        self.viewModel = HomeSectionListViewModel(category: category)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    init(
        category: MainHomeContentCategory,
        viewModel: HomeSectionListViewModel
    ) {
        self.category = category
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureNavigationBarAppearance()
        title = category.title
        configureCollectionView()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadInitialContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionViewFlowLayout.invalidateLayout()
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: ThemeColor.highlight
        ]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = ThemeColor.background
        appearance.shadowColor = ThemeColor.separator
        appearance.titleTextAttributes = titleAttributes
        appearance.largeTitleTextAttributes = titleAttributes

        navigationItem.standardAppearance = appearance
        navigationItem.compactAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactScrollEdgeAppearance = appearance
        navigationItem.largeTitleDisplayMode = .never
    }

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
        collectionViewFlowLayout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionView.register(
            HomeSectionListFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: HomeSectionListFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            HomeSectionListItemCollectionViewCell.self,
            forCellWithReuseIdentifier: HomeSectionListItemCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        cancelLoadNextPageTask()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitial()
        }
    }

    private func selectFilter(id: Int) {
        cancelLoadNextPageTask()
        viewModel.selectGenre(id: id)
    }

    private func observeViewModelState() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                render(state: viewModel.state)
                observeViewModelState()
            }
        }
    }

    private func render(state: HomeSectionListViewState) {
        switch state {
        case .idle, .loading:
            filters = []
            items = []
            isFilterSkeletonVisible = true
            setLoadingVisible(state == .loading)
            collectionView.backgroundView = nil

        case .empty:
            filters = []
            items = []
            isFilterSkeletonVisible = false
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: .emptyContent)

        case .failed(let errorMessage):
            filters = []
            items = []
            isFilterSkeletonVisible = false
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: errorMessage) { [weak self] in
                self?.loadInitialContent()
            }

        case .loaded(let content):
            filters = content.genres
            items = content.displayedItems
            isFilterSkeletonVisible = false
            setLoadingVisible(false)
            collectionView.backgroundView = content.displayedItems.isEmpty
                ? ErrorMessageView(message: .emptyContent)
                : nil
        }

        collectionView.reloadData()
    }

    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else {
            return
        }

        let currentItemID = items[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentItemID: currentItemID)

            case .idle, .loading, .empty, .failed:
                break
            }
        }
    }

    private func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }

    private func configureFilterHeader(_ headerView: UICollectionReusableView) {
        guard let headerView = headerView as? HomeSectionListFilterHeaderView else { return }

        headerView.configure(
            filters: filters,
            isExpanded: isFilterPageSheetPresented,
            isShowingSkeleton: isFilterSkeletonVisible
        )
        headerView.onFilterSelected = { [weak self] id in
            self?.selectFilter(id: id)
        }
        headerView.onShowAllFilters = { [weak self] in
            self?.presentFilterPageSheet()
        }
    }

    private func presentFilterPageSheet() {
        guard !filters.isEmpty else { return }
        setFilterPageSheetPresented(true)

        router.showGenrePageSheet(
            filters: filters,
            onFilterSelected: { [weak self] id in
                self?.selectFilter(id: id)
            },
            onDismiss: { [weak self] in
                self?.setFilterPageSheetPresented(false)
            }
        )
    }

    private func setFilterPageSheetPresented(_ isPresented: Bool) {
        isFilterPageSheetPresented = isPresented

        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(
            ofKind: UICollectionView.elementKindSectionHeader
        ) {
            let reusableView = collectionView.supplementaryView(
                forElementKind: UICollectionView.elementKindSectionHeader,
                at: indexPath
            )

            (reusableView as? HomeSectionListFilterHeaderView)?.setShowAllButtonExpanded(
                isPresented,
                animated: true
            )
        }
    }
}

// MARK: - UICollectionViewDataSource

extension HomeSectionListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        shouldShowContentSection ? 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isFilterSkeletonVisible ? 0 : items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeSectionListItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? HomeSectionListItemCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(
                with: items[indexPath.item],
                imageHeight: MovieGridLayoutMetrics.posterHeight(for: collectionView.bounds.width)
            )
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: HomeSectionListFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if kind == UICollectionView.elementKindSectionHeader {
            configureFilterHeader(reusableView)
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension HomeSectionListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showDetail(for: items[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        loadNextPageIfNeeded(for: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: shouldShowFilterHeader ? Layout.filterHeaderHeight : 0
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        MovieGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard !isFilterSkeletonVisible else { return .zero }

        return UIEdgeInsets(
            top: 12,
            left: MovieGridLayoutMetrics.horizontalInset,
            bottom: 24,
            right: MovieGridLayoutMetrics.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        MovieGridLayoutMetrics.itemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        MovieGridLayoutMetrics.itemSpacing
    }
}

// MARK: - Private Helpers

private extension HomeSectionListViewController {

    var shouldShowContentSection: Bool {
        shouldShowFilterHeader || !items.isEmpty
    }

    var shouldShowFilterHeader: Bool {
        isFilterSkeletonVisible || !filters.isEmpty
    }
}
