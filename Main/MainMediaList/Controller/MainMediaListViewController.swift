//
//  MainMediaListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import UIKit

// MARK: - MainMediaListViewController

@MainActor
final class MainMediaListViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
    }

    // MARK: - Properties

    private let mediaKind: MediaKind
    private let viewModel: MainMediaListViewModel
    private let sceneBuilder: MediaListSceneBuilding
    private lazy var router: MainMediaListRouting = MainMediaListRouter(
        sourceViewController: self,
        mediaKind: mediaKind,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var filters: [MainMediaGenreItem] = []
    private var items: [MediaGridItem] = []

    private var isFilterSkeletonVisible = true
    private var isFilterPageSheetPresented = false

    private var loadTask: Task<Void, Never>?
    private var filterSelectionTask: Task<Void, Never>?
    private var sortSelectionTask: Task<Void, Never>?

    private let paginationTaskController = MediaGridPaginationTaskController()

    // MARK: - UI Components

    private lazy var searchResultsViewController: UIViewController = sceneBuilder
        .makeSearchResultsViewController(
            mediaKind: mediaKind,
            onItemSelected: { [weak self] itemID in
                self?.showSearchResultDetail(itemID: itemID)
            },
            onSortBarButtonVisibilityChanged: { [weak self] isVisible, selectedOption in
                self?.updateSearchSortBarButtonVisibility(
                    isVisible: isVisible,
                    selectedSortOption: selectedOption
                )
            }
        )

    private var searchResultsHandler: (any SearchResultsHandling)? {
        searchResultsViewController as? any SearchResultsHandling
    }

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: searchResultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = mediaKind.mediaListSearchPlaceholder(
            localization: interfaceLocalization
        )
        searchController.obscuresBackgroundDuringPresentation = true
        return searchController
    }()

    private lazy var sortBarButtonItem: UIBarButtonItem = {
        let item = AppFactory.SortMenu.makeBarButtonItem(
            selectedOption: nil as MediaSortOrder?,
            localization: interfaceLocalization,
            onSelect: { [weak self] option in
                self?.selectSortOption(option)
            }
        )
        self.applySortBarButtonAccessibility(to: item, selectedOption: nil)
        return item
    }()

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        viewModel: MainMediaListViewModel,
        sceneBuilder: MediaListSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.mediaKind = mediaKind
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
        viewModel.bind { [weak self] state in
            self?.render(state: state)
        }
        loadInitialContent()
    }

    // MARK: - Routing

    func routeToGenre(id: Int) {
        guard id > 0 else { return }

        searchController.searchBar.text = nil
        searchResultsHandler?.reset()
        searchController.isActive = false
        loadTask?.cancel()
        filterSelectionTask?.cancel()
        sortSelectionTask?.cancel()
        cancelLoadNextPageTask()

        filterSelectionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent(selectingGenreID: id)
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
        collectionViewFlowLayout.minimumLineSpacing = MediaGridLayoutMetrics.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = MediaGridLayoutMetrics.itemSpacing
        collectionView.register(
            MainMediaListFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MainMediaListFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            MainMediaListItemCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMediaListItemCollectionViewCell.reuseIdentifier
        )
    }

    private func configureSearchBar() {
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        definesPresentationContext = true
        searchController.searchBar.searchTextField.accessibilityLabel = mediaKind.mediaListSearchPlaceholder(
            localization: interfaceLocalization
        )
        searchController.searchBar.searchTextField.accessibilityHint = mediaKind.mediaListSearchAccessibilityHint(
            localization: interfaceLocalization
        )
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

    private func render(state: MainMediaListViewState) {
        switch state {
        case .idle, .loading:
            filters = []
            items = []
            isFilterSkeletonVisible = true
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .refreshing(let content):
            filters = content.genres
            items = []
            isFilterSkeletonVisible = false
            navigationItem.title = mediaKind.mediaListGenreTitle(
                genreName: content.selectedGenre.name,
                localization: interfaceLocalization
            )
            collectionView.backgroundView = nil
            hideSortBarButtonItem()

        case .empty:
            renderUnavailableListState(
                title: mediaKind.mediaListEmptyTitle(localization: interfaceLocalization),
                message: mediaKind.mediaListEmptyMessage(localization: interfaceLocalization),
                systemImageName: mediaKind.systemImageName
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
            items = content.items
            isFilterSkeletonVisible = false
            navigationItem.title = mediaKind.mediaListGenreTitle(
                genreName: content.selectedGenre.name,
                localization: interfaceLocalization
            )
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
            searchResultsHandler?.reset()
            hideSortBarButtonItem()
            return
        }

        searchResultsHandler?.submitSearch(keyword: trimmedKeyword)
    }

    private func renderSearchTypingLoadingIfNeeded(keyword: String) {
        guard !keyword.isEmpty else { return }
        searchResultsHandler?.showTypingLoading()
        hideSortBarButtonItem()
    }

    private func showSortBarButtonItem(
        selectedSortOption: MediaSortOrder?,
        isSearchMode: Bool = false
    ) {
        sortBarButtonItem.menu = AppFactory.SortMenu.makeMenu(
            selectedOption: selectedSortOption,
            localization: interfaceLocalization,
            onSelect: { [weak self] option in
                self?.selectSortOption(option, isSearchMode: isSearchMode)
            }
        )
        applySortBarButtonAccessibility(to: sortBarButtonItem, selectedOption: selectedSortOption)
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

    private func applySortBarButtonAccessibility(
        to item: UIBarButtonItem,
        selectedOption: MediaSortOrder?
    ) {
        item.accessibilityLabel = mediaKind.mediaListSortAccessibilityLabel(
            localization: interfaceLocalization
        )
        item.accessibilityValue = selectedOption?.title(localization: interfaceLocalization)
            ?? interfaceLocalization.string(
                "common.value.not_selected",
                defaultValue: "Not selected"
            )
        item.accessibilityHint = mediaKind.mediaListSortAccessibilityHint(
            localization: interfaceLocalization
        )
    }

    private func selectSortOption(
        _ option: MediaSortOrder,
        isSearchMode: Bool = false
    ) {
        if isSearchMode {
            searchResultsHandler?.selectSortOption(option)
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

extension MainMediaListViewController: UICollectionViewDataSource {

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
            withReuseIdentifier: MainMediaListItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainMediaListItemCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(
                with: items[indexPath.item],
                imageHeight: MediaGridLayoutMetrics.posterHeight(for: collectionView.bounds.width),
                mediaKind: mediaKind,
                localization: interfaceLocalization
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
            withReuseIdentifier: MainMediaListFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MainMediaListFilterHeaderView {
            headerView.configure(
                filters: filters,
                isExpanded: isFilterPageSheetPresented,
                isShowingSkeleton: isFilterSkeletonVisible,
                localization: interfaceLocalization
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

extension MainMediaListViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        let itemID = items[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showMediaDetail(itemID: itemID)
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
        MediaGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard !isFilterSkeletonVisible else { return .zero }

        return UIEdgeInsets(
            top: 12,
            left: MediaGridLayoutMetrics.horizontalInset,
            bottom: 24,
            right: MediaGridLayoutMetrics.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        MediaGridLayoutMetrics.itemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        MediaGridLayoutMetrics.itemSpacing
    }
}

// MARK: - UISearchResultsUpdating

extension MainMediaListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        guard !router.shouldIgnoreSearchCancellation else { return }

        let keyword = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !keyword.isEmpty else {
            searchResultsHandler?.reset()
            hideSortBarButtonItem()
            return
        }

        renderSearchTypingLoadingIfNeeded(keyword: keyword)
    }
}

// MARK: - UISearchBarDelegate

extension MainMediaListViewController: UISearchBarDelegate {

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

private extension MainMediaListViewController {

    var shouldShowContentSection: Bool {
        shouldShowFilterHeader || !items.isEmpty
    }

    var shouldShowFilterHeader: Bool {
        isFilterSkeletonVisible || !filters.isEmpty
    }

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MediaGridPaginationState.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else { return }

        let currentItemID = items[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentItemID: currentItemID)

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
        items = []
        isFilterSkeletonVisible = false
        collectionView.backgroundView = ErrorMessageView(
            message: ErrorMessage(
                title: title,
                message: message,
                systemImageName: systemImageName
            ),
            localization: interfaceLocalization
        )
    }

    func showSearchResultDetail(itemID: Int) {
        router.showMediaDetailFromSearch(
            itemID: itemID,
            searchController: searchController,
            onSearchDismissed: { [weak self] in
                guard let self else { return }
                searchResultsHandler?.reset()
                render(state: viewModel.state)
            }
        )
    }

    func restoreListAfterSearch() {
        searchResultsHandler?.reset()
        render(state: viewModel.state)
    }

    func updateSearchSortBarButtonVisibility(
        isVisible: Bool,
        selectedSortOption: MediaSortOrder?
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
            kind: mediaKind,
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
            (reusableView as? MainMediaListFilterHeaderView)?.setShowAllButtonExpanded(
                isPresented,
                animated: true
            )
        }
    }
}
