//
//  MainMovieListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import Observation
import UIKit

// MARK: - MainMovieListViewController

@MainActor
final class MainMovieListViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let viewModel: MainMovieListViewModel
    private lazy var router: MainMovieListRouting = MainMovieListRouter(sourceViewController: self)
    private var filters: [MainMovieGenreItem] = []
    private var movies: [MovieGridMovieItem] = []
    private var isFilterSkeletonVisible = true
    private var isFilterPageSheetPresented = false
    private var loadTask: Task<Void, Never>?
    private var filterSelectionTask: Task<Void, Never>?
    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - UI Components

    private lazy var searchResultsViewController: MainMovieSearchResultsViewController = {
        let viewController = MainMovieSearchResultsViewController()
        viewController.onMovieSelected = { [weak self] movieID in
            self?.showSearchResultMovieDetail(movieID: movieID)
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
        searchController.searchBar.placeholder = "搜尋電影"
        searchController.obscuresBackgroundDuringPresentation = true
        return searchController
    }()

    private lazy var sortBarButtonItem = MovieSortMenuFactory.makeBarButtonItem(
        selectedOption: nil,
        onSelect: { [weak self] option in
            self?.selectSortOption(option)
        }
    )

    // MARK: - Initialization

    init(viewModel: MainMovieListViewModel = MainMovieListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainMovieListViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
        filterSelectionTask?.cancel()
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
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
        collectionViewFlowLayout.sectionInset = .zero
        collectionViewFlowLayout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionView.register(
            MainMovieListFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainMovieListFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainMovieListMovieCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMovieListMovieCollectionViewCell.reuseIdentifier
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
        cancelLoadNextPageTask()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent()
        }
    }

    private func selectFilter(id: Int) {
        filterSelectionTask?.cancel()
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
            Task { @MainActor [weak self] in
                guard let self else { return }
                render(state: viewModel.state)
                observeViewModelState()
            }
        }
    }

    private func render(state: MainMovieListViewState) {
        switch state {
        case .idle, .loading:
            filters = []
            movies = []
            isFilterSkeletonVisible = true
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .refreshing(let content):
            filters = content.genres
            movies = []
            isFilterSkeletonVisible = false
            navigationItem.title = "\(content.selectedGenre.name)電影"
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .empty:
            renderUnavailableListState(
                title: "沒有電影資料",
                message: "目前沒有可顯示的電影。",
                systemImageName: "film"
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
            movies = content.movies
            isFilterSkeletonVisible = false
            navigationItem.title = "\(content.selectedGenre.name)電影"
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
        selectedSortOption: MovieSortOption?,
        isSearchMode: Bool = false
    ) {
        sortBarButtonItem.menu = MovieSortMenuFactory.makeMenu(
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
        _ option: MovieSortOption,
        isSearchMode: Bool = false
    ) {
        if isSearchMode {
            searchResultsViewController.selectSortOption(option)
            return
        }

        viewModel.selectSortOption(option)
    }
}

// MARK: - UICollectionViewDataSource

extension MainMovieListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        shouldShowContentSection ? 1 : 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isFilterSkeletonVisible ? 0 : movies.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainMovieListMovieCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainMovieListMovieCollectionViewCell,
           movies.indices.contains(indexPath.item) {
            cell.configure(
                with: movies[indexPath.item],
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
            withReuseIdentifier: MainMovieListFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainMovieListFilterHeaderView {
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

extension MainMovieListViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        let movieID = movies[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showMovieDetail(movieID: movieID)
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

extension MainMovieListViewController: UISearchResultsUpdating {

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

extension MainMovieListViewController: UISearchBarDelegate {

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

private extension MainMovieListViewController {

    var shouldShowContentSection: Bool {
        shouldShowFilterHeader || !movies.isEmpty
    }

    var shouldShowFilterHeader: Bool {
        isFilterSkeletonVisible || !filters.isEmpty
    }

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: movies.count
        ) else { return }

        let currentMovieID = movies[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentMovieID: currentMovieID)

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
        movies = []
        isFilterSkeletonVisible = false
        collectionView.backgroundView = ErrorMessageView(
            message: ErrorMessage(
                title: title,
                message: message,
                systemImageName: systemImageName
            )
        )
    }

    func showSearchResultMovieDetail(movieID: Int) {
        router.showMovieDetailFromSearch(
            movieID: movieID,
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
        selectedSortOption: MovieSortOption?
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
            (reusableView as? MainMovieListFilterHeaderView)?.setShowAllButtonExpanded(
                isPresented,
                animated: true
            )
        }
    }
}
