//
//  MainSearchViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Observation
import UIKit

// MARK: - MainSearchViewController

@MainActor
final class MainSearchViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let searchResultHeight: CGFloat = 112
        static let trendingTopInset: CGFloat = 12
        static let trendingBottomInset: CGFloat = 24
        static let filterHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let viewModel: MainSearchViewModel
    private lazy var router: MainSearchRouting = MainSearchRouter(sourceViewController: self)

    private var filters: [MainSearchFilterItem] = []
    private var results: [MainSearchResultItem] = []
    private var dailyTrendingItems: [MainSearchResultItem] = []
    private var isShowingDailyTrending = false

    private var canLoadNextPage = false
    private var isLoadingNextPage = false

    private var searchTask: Task<Void, Never>?
    private var dailyTrendingTask: Task<Void, Never>?

    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - Override Points

    override var collectionViewItemHeight: CGFloat {
        Layout.searchResultHeight
    }

    override var updatesFlowLayoutItemSizeAutomatically: Bool {
        false
    }

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "搜尋電影、劇集、人物"
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    // MARK: - Initialization

    init(viewModel: MainSearchViewModel = MainSearchViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainSearchViewModel()
        super.init(coder: coder)
    }

    deinit {
        searchTask?.cancel()
        dailyTrendingTask?.cancel()
    }

    // MARK: - Template Methods

    override func configureView() {
        super.configureView()
        configureCollectionView()
        configureNavigationBarAppearance()
        configureSearchBar()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadDailyTrending()
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
        navigationItem.title = "搜尋"
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainSearchFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainSearchFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainSearchResultCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchResultCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainSearchTrendingCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchTrendingCollectionViewCell.reuseIdentifier
        )
    }

    private func configureSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    // MARK: - Rendering

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

    private func render(state: MainSearchViewState) {
        setLoadingVisible(false, animated: false)

        switch state {
        case .idle:
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .dailyTrendingLoading:
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil
            setLoadingVisible(true, animated: false)

        case .dailyTrending(let content):
            filters = []
            results = []
            dailyTrendingItems = content.items
            isShowingDailyTrending = true
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .dailyTrendingEmpty:
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "目前沒有熱門內容",
                    message: "稍後再回來看看近期熱門的電影、劇集與人物。",
                    systemImageName: "flame"
                )
            )

        case .typing:
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchTypingLoadingView()

        case .searching(let keyword):
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchSubmittedLoadingView(keyword: keyword)

        case .results(let content):
            filters = content.filters
            results = content.results
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = makeFilteredEmptyViewIfNeeded(for: content)

        case .empty(let keyword):
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "找不到結果",
                    message: "沒有符合「\(keyword)」的搜尋結果。",
                    systemImageName: "magnifyingglass"
                )
            )

        case .failed(let errorMessage):
            filters = []
            results = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: errorMessage
            ) { [weak self] in
                self?.retryCurrentRequest()
            }
        }

        collectionView.reloadData()
        collectionView.collectionViewLayout.invalidateLayout()
    }

    // MARK: - Search

    private func submitSearch(keyword: String?) {
        searchTask?.cancel()
        dailyTrendingTask?.cancel()
        cancelLoadNextPageTask()

        let trimmedKeyword = (keyword ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            resetSearch()
            return
        }

        viewModel.showSearchLoading(keyword: trimmedKeyword)
        searchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.search(keyword: trimmedKeyword)
        }
    }

    private func resetSearch() {
        searchTask?.cancel()
        cancelLoadNextPageTask()
        viewModel.reset()
        loadDailyTrending()
    }
}

// MARK: - UICollectionViewDataSource

extension MainSearchViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        dailyTrendingItems.isEmpty && filters.isEmpty && results.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isShowingDailyTrending ? dailyTrendingItems.count : results.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        if isShowingDailyTrending {
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainSearchTrendingCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainSearchTrendingCollectionViewCell,
               dailyTrendingItems.indices.contains(indexPath.item) {
                cell.configure(
                    with: dailyTrendingItems[indexPath.item],
                    imageHeight: MovieGridLayoutMetrics.posterHeight(
                        for: collectionView.bounds.width
                    )
                )
            }

            return cell
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainSearchResultCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainSearchResultCollectionViewCell,
           results.indices.contains(indexPath.item) {
            cell.configure(with: results[indexPath.item])
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
            withReuseIdentifier: MainSearchFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainSearchFilterHeaderView {
            headerView.configure(filters: filters)
            headerView.onFilterSelected = { [weak self] filter in
                self?.selectFilter(filter)
            }
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainSearchViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let items = isShowingDailyTrending ? dailyTrendingItems : results
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
            height: filters.isEmpty ? 0 : Layout.filterHeaderHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard isShowingDailyTrending else {
            return CGSize(
                width: collectionView.bounds.width,
                height: Layout.searchResultHeight
            )
        }

        return MovieGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard isShowingDailyTrending else { return .zero }

        return UIEdgeInsets(
            top: Layout.trendingTopInset,
            left: MovieGridLayoutMetrics.horizontalInset,
            bottom: Layout.trendingBottomInset,
            right: MovieGridLayoutMetrics.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        isShowingDailyTrending ? MovieGridLayoutMetrics.itemSpacing : 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        isShowingDailyTrending ? MovieGridLayoutMetrics.itemSpacing : 0
    }
}

// MARK: - UISearchResultsUpdating

extension MainSearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        let keyword = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyword.isEmpty else {
            resetSearch()
            return
        }

        dailyTrendingTask?.cancel()
        cancelLoadNextPageTask()
        viewModel.showTypingLoading()
    }
}

// MARK: - UISearchBarDelegate

extension MainSearchViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        submitSearch(keyword: searchBar.text)
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        resetSearch()
    }
}

// MARK: - Private Methods

private extension MainSearchViewController {

    func loadDailyTrending() {
        dailyTrendingTask?.cancel()
        dailyTrendingTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadDailyTrending()
        }
    }

    func retryCurrentRequest() {
        let keyword = searchController.searchBar.text
        let trimmedKeyword = (keyword ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedKeyword.isEmpty else {
            loadDailyTrending()
            return
        }

        submitSearch(keyword: trimmedKeyword)
    }

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        let items = isShowingDailyTrending ? dailyTrendingItems : results
        guard items.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else { return }

        let currentResultID = items[indexPath.item].id
        let loadsDailyTrending = isShowingDailyTrending

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            if loadsDailyTrending {
                await viewModel.loadNextDailyTrendingPageIfNeeded(
                    currentResultID: currentResultID
                )
            } else {
                await viewModel.loadNextPageIfNeeded(
                    currentResultID: currentResultID
                )
            }
        }
    }

    func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }

    func selectFilter(_ filter: MainSearchFilter) {
        viewModel.selectFilter(filter)
    }

    func makeFilteredEmptyViewIfNeeded(for content: MainSearchContent) -> UIView? {
        guard content.results.isEmpty else { return nil }

        return ErrorMessageView(
            message: ErrorMessage(
                title: "沒有\(content.selectedFilter.title)結果",
                message: "目前已載入的搜尋結果沒有符合此分類的內容。",
                systemImageName: "line.3.horizontal.decrease.circle"
            )
        )
    }
}
