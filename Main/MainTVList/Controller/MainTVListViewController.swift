//
//  MainTVListViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Observation
import SnapKit
import UIKit

// MARK: - MainTVListViewController

@MainActor
final class MainTVListViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let viewModel: MainTVListViewModel
    private lazy var router: MainTVListRouting = MainTVListRouter(sourceViewController: self)

    private var filters: [MainTVGenreItem] = []
    private var series: [TVGridSeriesItem] = []

    private var isFilterSkeletonVisible = true
    private var isFilterPageSheetPresented = false

    private var loadTask: Task<Void, Never>?
    private var filterSelectionTask: Task<Void, Never>?
    private var sortSelectionTask: Task<Void, Never>?

    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - UI Components

    private lazy var searchResultsViewController: MainTVSearchResultsViewController = {
        let viewController = MainTVSearchResultsViewController()
        viewController.onSeriesSelected = { [weak self] seriesID in
            self?.showSearchResultTVDetail(seriesID: seriesID)
        }
        viewController.onSortBarButtonVisibilityChanged = { [weak self] isVisible, selectedOption in
            self?.updateSearchSortBarButtonVisibility(
                isVisible: isVisible,
                selectedSortOption: selectedOption
            )
        }
        return viewController
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "搜尋劇集"
        searchController.obscuresBackgroundDuringPresentation = true
        return searchController
    }()

    private lazy var sortBarButtonItem = AppFactory.SortMenu.makeBarButtonItem(
        selectedOption: nil as TVSortOption?,
        onSelect: { [weak self] option in
            self?.selectSortOption(option)
        }
    )

    // MARK: - Initialization

    convenience init(initialGenreID: Int) {
        self.init(
            viewModel: MainTVListViewModel(initialGenreID: initialGenreID)
        )
    }

    init(viewModel: MainTVListViewModel = MainTVListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainTVListViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
        filterSelectionTask?.cancel()
        sortSelectionTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureNavigationBarAppearance()
        configureCollectionView()
        configureSearchBar()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadInitialContent()
    }

    // MARK: - Routing

    func routeToGenre(id: Int) {
        guard id > 0 else { return }

        searchController.searchBar.text = nil
        searchResultsViewController.reset()
        searchController.isActive = false
        loadTask?.cancel()
        filterSelectionTask?.cancel()
        sortSelectionTask?.cancel()
        cancelLoadNextPageTask()

        filterSelectionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadContent(selectingGenreID: id)
        }
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
    }

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
        collectionViewFlowLayout.sectionInset = .zero
        collectionViewFlowLayout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionView.register(
            MainTVListFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainTVListFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainTVListSeriesCollectionViewCell.self,
            forCellWithReuseIdentifier: MainTVListSeriesCollectionViewCell.reuseIdentifier
        )
    }

    private func configureSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        sortSelectionTask?.cancel()
        cancelLoadNextPageTask()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent()
        }
    }

    private func selectFilter(id: Int) {
        filterSelectionTask?.cancel()
        sortSelectionTask?.cancel()
        cancelLoadNextPageTask()
        filterSelectionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.selectGenre(id: id)
        }
    }

    private func observeViewModelState() {
        withObservationTracking {
            _ = viewModel.state
        } onChange: { [weak self] in
            Task(priority: .userInitiated) { @MainActor [weak self] in
                guard let self else { return }
                render(state: viewModel.state)
                observeViewModelState()
            }
        }
    }

    private func render(state: MainTVListViewState) {
        switch state {
        case .idle, .loading:
            filters = []
            series = []
            isFilterSkeletonVisible = true
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .refreshing(let content):
            filters = content.genres
            series = []
            isFilterSkeletonVisible = false
            navigationItem.title = "\(content.selectedGenre.name)劇集"
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .empty:
            renderUnavailableListState(
                title: "沒有劇集資料",
                message: "目前沒有可顯示的劇集。",
                systemImageName: "tv"
            )
            hideSortBarButtonItem()

        case .failed(let errorMessage):
            renderUnavailableListState(
                title: errorMessage.title,
                message: errorMessage.message,
                systemImageName: errorMessage.systemImageName
            )
            hideSortBarButtonItem()

        case .loaded(let content):
            filters = content.genres
            series = content.series
            isFilterSkeletonVisible = false
            navigationItem.title = "\(content.selectedGenre.name)劇集"
            collectionView.backgroundView = nil
            showSortBarButtonItem(selectedSortOption: content.selectedSortOption)
        }

        collectionView.reloadData()
    }

    // MARK: - Search

    private func submitSearch(keyword: String?) {
        cancelLoadNextPageTask()
        let trimmedKeyword = (keyword ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            searchResultsViewController.reset()
            hideSortBarButtonItem()
            return
        }

        searchResultsViewController.submitSearch(keyword: trimmedKeyword)
    }

    private func renderSearchTypingLoadingIfNeeded(keyword: String) {
        guard !keyword.isEmpty else { return }
        searchResultsViewController.showTypingLoading()
        hideSortBarButtonItem()
    }

    private func showSortBarButtonItem(
        selectedSortOption: TVSortOption?,
        isSearchMode: Bool = false
    ) {
        sortBarButtonItem.menu = AppFactory.SortMenu.makeMenu(
            selectedOption: selectedSortOption,
            onSelect: { [weak self] option in
                self?.selectSortOption(option, isSearchMode: isSearchMode)
            }
        )
        applySortBarButtonItem(isSearchMode: isSearchMode)
    }

    private func hideSortBarButtonItem() {
        navigationItem.rightBarButtonItem = nil
        searchResultsViewController.navigationItem.rightBarButtonItem = nil
    }

    private func applySortBarButtonItem(isSearchMode: Bool) {
        if isSearchMode {
            searchResultsViewController.navigationItem.rightBarButtonItem = sortBarButtonItem
            navigationItem.rightBarButtonItem = sortBarButtonItem
        } else {
            navigationItem.rightBarButtonItem = sortBarButtonItem
            searchResultsViewController.navigationItem.rightBarButtonItem = nil
        }
    }

    private func selectSortOption(
        _ option: TVSortOption,
        isSearchMode: Bool = false
    ) {
        if isSearchMode {
            searchResultsViewController.selectSortOption(option)
            return
        }

        sortSelectionTask?.cancel()
        cancelLoadNextPageTask()
        sortSelectionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.selectSortOption(option)
        }
    }
}

// MARK: - UICollectionViewDataSource

extension MainTVListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        shouldShowContentSection ? 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isFilterSkeletonVisible ? 0 : series.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainTVListSeriesCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainTVListSeriesCollectionViewCell,
           series.indices.contains(indexPath.item) {
            cell.configure(
                with: series[indexPath.item],
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
        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MainTVListFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainTVListFilterHeaderView {
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

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainTVListViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard series.indices.contains(indexPath.item) else { return }
        let seriesID = series[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showTVDetail(seriesID: seriesID)
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

// MARK: - UISearchResultsUpdating

extension MainTVListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard !router.shouldIgnoreSearchCancellation else { return }

        let keyword = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyword.isEmpty else {
            searchResultsViewController.reset()
            hideSortBarButtonItem()
            return
        }

        renderSearchTypingLoadingIfNeeded(keyword: keyword)
    }
}

// MARK: - UISearchBarDelegate

extension MainTVListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        submitSearch(keyword: searchBar.text)
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        guard !router.shouldIgnoreSearchCancellation else { return }
        restoreListAfterSearch()
    }
}

// MARK: - Private Methods

private extension MainTVListViewController {

    var shouldShowContentSection: Bool {
        shouldShowFilterHeader || !series.isEmpty
    }

    var shouldShowFilterHeader: Bool {
        isFilterSkeletonVisible || !filters.isEmpty
    }

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard series.indices.contains(indexPath.item) else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: series.count
        ) else { return }

        let currentSeriesID = series[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentSeriesID: currentSeriesID)

            case .idle, .loading, .refreshing, .empty, .failed:
                break
            }
        }
    }

    func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }

    func renderUnavailableListState(
        title: String,
        message: String,
        systemImageName: String
    ) {
        filters = []
        series = []
        isFilterSkeletonVisible = false
        collectionView.backgroundView = ErrorMessageView(
            message: ErrorMessage(
                title: title,
                message: message,
                systemImageName: systemImageName
            )
        )
    }

    func showSearchResultTVDetail(seriesID: Int) {
        router.showTVDetailFromSearch(
            seriesID: seriesID,
            searchController: searchController,
            onSearchDismissed: { [weak self] in
                guard let self else { return }
                searchResultsViewController.reset()
                render(state: viewModel.state)
            }
        )
    }

    func restoreListAfterSearch() {
        searchResultsViewController.reset()
        render(state: viewModel.state)
    }

    func updateSearchSortBarButtonVisibility(
        isVisible: Bool,
        selectedSortOption: TVSortOption?
    ) {
        guard searchController.isActive else { return }

        if isVisible {
            showSortBarButtonItem(
                selectedSortOption: selectedSortOption,
                isSearchMode: true
            )
        } else {
            hideSortBarButtonItem()
        }
    }

    func presentFilterPageSheet() {
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

    func setFilterPageSheetPresented(_ isPresented: Bool) {
        isFilterPageSheetPresented = isPresented

        for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(
            ofKind: UICollectionView.elementKindSectionHeader
        ) {
            let reusableView = collectionView.supplementaryView(
                forElementKind: UICollectionView.elementKindSectionHeader,
                at: indexPath
            )
            (reusableView as? MainTVListFilterHeaderView)?.setShowAllButtonExpanded(
                isPresented,
                animated: true
            )
        }
    }
}
