//
//  MainSearchViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import UIKit

// MARK: - MainSearchViewController

@MainActor
final class MainSearchViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        private static let minimumSearchResultHeight: CGFloat = 112
        private static let minimumPopularPeopleHeight: CGFloat = 112
        private static let searchResultVerticalInset: CGFloat = 8
        private static let searchResultLabelSpacing: CGFloat = 4
        private static let popularPeopleAvatarSize: CGFloat = 72
        private static let popularPeopleTitleTopSpacing: CGFloat = 4
        static let trendingTopInset: CGFloat = 12
        static let trendingBottomInset: CGFloat = 24
        static let filterHeaderHeight: CGFloat = 56

        static var searchResultHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .headline).lineHeight) * 2
            let subtitleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption2).lineHeight) * 2
            return max(
                minimumSearchResultHeight,
                (searchResultVerticalInset * 2) + titleHeight + searchResultLabelSpacing + subtitleHeight
            )
        }

        static var popularPeopleHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            return max(
                minimumPopularPeopleHeight,
                popularPeopleAvatarSize + popularPeopleTitleTopSpacing + titleHeight
            )
        }
    }

    private enum Section: Equatable {
        case recentSearchHistory
        case popularPeople
        case dailyTrending
        case searchResults
    }

    // MARK: - Properties

    private let viewModel: MainSearchViewModel
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: MainSearchRouting = MainSearchRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var filters: [MainSearchFilterItem] = []
    private var results: [MainSearchResultItem] = []
    private var recentSearchEntries: [SearchHistoryEntry] = []
    private var popularPeopleItems: [MainSearchResultItem] = []
    private var dailyTrendingItems: [MainSearchResultItem] = []
    private var isShowingDailyTrending = false

    private var canLoadNextPage = false
    private var isLoadingNextPage = false

    private var searchTask: Task<Void, Never>?
    private var dailyTrendingTask: Task<Void, Never>?

    private let paginationTaskController = MediaGridPaginationTaskController()

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = interfaceLocalization.string(
            "main_search.placeholder",
            defaultValue: "Search movies, TV shows, and people"
        )
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    // MARK: - Initialization

    init(
        viewModel: MainSearchViewModel,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.viewModel = viewModel
        self.sceneBuilder = sceneBuilder
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(interfaceLocalization)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTask?.cancel()
        dailyTrendingTask?.cancel()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.refreshRecentSearchEntriesIfShowingDailyTrending()
    }

    // MARK: - Template Methods

    override func configureView() {
        super.configureView()
        configureCollectionView()
        configureNavigationBarAppearance()
        configureSearchBar()
    }

    override func bindViewModel() {
        viewModel.bind { [weak self] state in
            self?.render(state: state)
        }
        loadDailyTrending()
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
        navigationItem.title = interfaceLocalization.string(
            "main_search.navigation.title",
            defaultValue: "Search"
        )
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = ThemeColor.clear
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
            MainSearchRecentHistoryCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchRecentHistoryCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainSearchTrendingCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchTrendingCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MainSearchPopularPeopleCollectionViewCell.self,
            forCellWithReuseIdentifier: MainSearchPopularPeopleCollectionViewCell.reuseIdentifier
        )
    }

    private func configureSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        searchController.searchBar.searchTextField.accessibilityLabel = interfaceLocalization.string(
            "main_search.accessibility.search.label",
            defaultValue: "Search movies, TV shows, and people"
        )
        searchController.searchBar.searchTextField.accessibilityHint = interfaceLocalization.string(
            "main_search.accessibility.search.hint",
            defaultValue: "Enter a keyword to search"
        )
    }

    // MARK: - Rendering

    private func render(state: MainSearchViewState) {
        setLoadingVisible(false, animated: false)

        switch state {
        case .idle:
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .dailyTrendingLoading:
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil
            setLoadingVisible(true, animated: false)

        case .dailyTrending(let content):
            filters = []
            results = []
            recentSearchEntries = content.recentSearchEntries
            popularPeopleItems = content.popularPeople
            dailyTrendingItems = content.items
            isShowingDailyTrending = true
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .dailyTrendingEmpty:
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: interfaceLocalization.string(
                        "main_search.trending_empty.title",
                        defaultValue: "No Trending Content Right Now"
                    ),
                    message: interfaceLocalization.string(
                        "main_search.trending_empty.message",
                        defaultValue: "Check back later for trending movies, TV shows, and people."
                    ),
                    systemImageName: "flame"
                ),
                localization: interfaceLocalization
            )

        case .typing:
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = SearchTypingLoadingView(
                localization: interfaceLocalization
            )

        case .searching(let keyword):
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = SearchSubmittedLoadingView(
                keyword: keyword,
                localization: interfaceLocalization
            )

        case .results(let content):
            filters = content.filters(localization: interfaceLocalization)
            results = content.results
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = makeFilteredEmptyViewIfNeeded(for: content)

        case .empty(let keyword):
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: interfaceLocalization.string(
                        "search.empty.title",
                        defaultValue: "No Results Found"
                    ),
                    message: interfaceLocalization.formatted(
                        "search.empty.message_format",
                        defaultValue: "No results matched “%@.”",
                        keyword
                    ),
                    systemImageName: "magnifyingglass"
                ),
                localization: interfaceLocalization
            )

        case .failed(let errorMessage):
            filters = []
            results = []
            recentSearchEntries = []
            popularPeopleItems = []
            dailyTrendingItems = []
            isShowingDailyTrending = false
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: errorMessage,
                localization: interfaceLocalization
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

        viewModel.addSearchHistory(keyword: trimmedKeyword)
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
        visibleSections.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard visibleSections.indices.contains(section) else { return 0 }

        switch visibleSections[section] {
        case .recentSearchHistory:
            return 1

        case .popularPeople:
            return 1

        case .dailyTrending:
            return dailyTrendingItems.count

        case .searchResults:
            return results.count
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard visibleSections.indices.contains(indexPath.section) else {
            return UICollectionViewCell()
        }

        switch visibleSections[indexPath.section] {
        case .recentSearchHistory:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainSearchRecentHistoryCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainSearchRecentHistoryCollectionViewCell {
                cell.configure(
                    entries: recentSearchEntries,
                    localization: interfaceLocalization,
                    onKeywordSelected: { [weak self] keyword in
                        self?.selectRecentSearch(keyword: keyword)
                    },
                    onKeywordDeleted: { [weak self] entry in
                        self?.deleteRecentSearch(entry: entry)
                    },
                    onEntryMoved: { [weak self] entry, destinationIndex in
                        self?.moveRecentSearch(entry: entry, to: destinationIndex)
                    }
                )
            }

            return cell

        case .popularPeople:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainSearchPopularPeopleCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainSearchPopularPeopleCollectionViewCell {
                cell.configure(people: popularPeopleItems) { [weak self] person in
                    self?.router.showDetail(for: person)
                }
            }

            return cell

        case .dailyTrending:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MainSearchTrendingCollectionViewCell.reuseIdentifier,
                for: indexPath
            )

            if let cell = cell as? MainSearchTrendingCollectionViewCell,
               dailyTrendingItems.indices.contains(indexPath.item) {
                cell.configure(
                    with: dailyTrendingItems[indexPath.item],
                    imageHeight: MediaGridLayoutMetrics.posterHeight(
                        for: collectionView.bounds.width
                    )
                )
            }

            return cell

        case .searchResults:
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
            headerView.configure(
                filters: filters,
                localization: interfaceLocalization
            )
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
        guard visibleSections.indices.contains(indexPath.section) else { return }

        let items: [MainSearchResultItem]

        switch visibleSections[indexPath.section] {
        case .recentSearchHistory:
            return

        case .popularPeople:
            return

        case .dailyTrending:
            items = dailyTrendingItems

        case .searchResults:
            items = results
        }

        guard items.indices.contains(indexPath.item) else { return }

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showDetail(for: items[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard visibleSections.indices.contains(indexPath.section),
              visibleSections[indexPath.section] != .recentSearchHistory,
              visibleSections[indexPath.section] != .popularPeople else {
            return
        }

        loadNextPageIfNeeded(for: indexPath)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        guard visibleSections.indices.contains(section),
              visibleSections[section] == .searchResults else {
            return .zero
        }

        return CGSize(
            width: collectionView.bounds.width,
            height: filters.isEmpty ? 0 : Layout.filterHeaderHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard visibleSections.indices.contains(indexPath.section) else {
            return .zero
        }

        switch visibleSections[indexPath.section] {
        case .recentSearchHistory:
            return CGSize(
                width: collectionView.bounds.width,
                height: MainSearchRecentHistoryCollectionViewCell.preferredHeight(
                    entryCount: recentSearchEntries.count
                )
            )

        case .popularPeople:
            return CGSize(
                width: collectionView.bounds.width,
                height: Layout.popularPeopleHeight
            )

        case .searchResults:
            return CGSize(
                width: collectionView.bounds.width,
                height: Layout.searchResultHeight
            )

        case .dailyTrending:
            return MediaGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard visibleSections.indices.contains(section) else { return .zero }

        switch visibleSections[section] {
        case .recentSearchHistory:
            return UIEdgeInsets(
                top: Layout.trendingTopInset,
                left: 0,
                bottom: 8,
                right: 0
            )

        case .popularPeople:
            return UIEdgeInsets(top: Layout.trendingTopInset, left: 0, bottom: 0, right: 0)

        case .searchResults:
            return .zero

        case .dailyTrending:
            return UIEdgeInsets(
                top: popularPeopleItems.isEmpty ? Layout.trendingTopInset : 0,
                left: MediaGridLayoutMetrics.horizontalInset,
                bottom: Layout.trendingBottomInset,
                right: MediaGridLayoutMetrics.horizontalInset
            )
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        guard visibleSections.indices.contains(section),
              visibleSections[section] == .dailyTrending else {
            return 0
        }

        return MediaGridLayoutMetrics.itemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        guard visibleSections.indices.contains(section),
              visibleSections[section] == .dailyTrending else {
            return 0
        }

        return MediaGridLayoutMetrics.itemSpacing
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

    private var visibleSections: [Section] {
        if isShowingDailyTrending {
            var sections: [Section] = []

            if !recentSearchEntries.isEmpty {
                sections.append(.recentSearchHistory)
            }

            if !popularPeopleItems.isEmpty {
                sections.append(.popularPeople)
            }

            if !dailyTrendingItems.isEmpty {
                sections.append(.dailyTrending)
            }

            return sections
        }

        return filters.isEmpty && results.isEmpty ? [] : [.searchResults]
    }

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

        guard MediaGridPaginationState.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else { return }

        let currentItemID = items[indexPath.item].id
        let loadsDailyTrending = isShowingDailyTrending

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            if loadsDailyTrending {
                await viewModel.loadNextDailyTrendingPageIfNeeded(
                    currentItemID: currentItemID
                )
            } else {
                await viewModel.loadNextPageIfNeeded(
                    currentItemID: currentItemID
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

    func selectRecentSearch(keyword: String) {
        searchController.searchBar.text = keyword
        submitSearch(keyword: keyword)
        searchController.searchBar.resignFirstResponder()
    }

    func deleteRecentSearch(entry: SearchHistoryEntry) {
        viewModel.removeSearchHistory(id: entry.id)
    }

    func moveRecentSearch(entry: SearchHistoryEntry, to destinationIndex: Int) {
        viewModel.moveSearchHistory(id: entry.id, to: destinationIndex)
    }

    func makeFilteredEmptyViewIfNeeded(for content: MainSearchContent) -> UIView? {
        guard content.results.isEmpty else { return nil }

        return ErrorMessageView(
            message: ErrorMessage(
                title: content.selectedFilter.emptyResultsTitle(localization: interfaceLocalization),
                message: interfaceLocalization.string(
                    "main_search.filtered_empty.message",
                    defaultValue: "None of the loaded results match this category."
                ),
                systemImageName: "line.3.horizontal.decrease.circle"
            ),
            localization: interfaceLocalization
        )
    }
}
