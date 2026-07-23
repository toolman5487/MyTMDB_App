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

    // MARK: - Properties

    private let viewModel: MainSearchViewModel
    private lazy var router: MainSearchRouting = MainSearchRouter(sourceViewController: self)
    private var filters: [MainSearchFilterItem] = []
    private var results: [MainSearchResultItem] = []
    private var canLoadNextPage = false
    private var isLoadingNextPage = false
    private var searchTask: Task<Void, Never>?
    private let paginationTaskController = MovieGridPaginationTaskController()

    override var collectionViewItemHeight: CGFloat {
        112
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
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
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
        switch state {
        case .idle:
            filters = []
            results = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "開始搜尋",
                    message: "輸入關鍵字搜尋電影、劇集與人物。",
                    systemImageName: "magnifyingglass"
                )
            )

        case .typing:
            filters = []
            results = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchTypingLoadingView()

        case .searching(let keyword):
            filters = []
            results = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchSubmittedLoadingView(keyword: keyword)

        case .results(let content):
            filters = content.filters
            results = content.results
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = makeFilteredEmptyViewIfNeeded(for: content)

        case .empty(let keyword):
            filters = []
            results = []
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
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(message: errorMessage)
        }

        collectionView.reloadData()
    }

    // MARK: - Search

    private func submitSearch(keyword: String?) {
        searchTask?.cancel()
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
    }
}

// MARK: - UICollectionViewDataSource

extension MainSearchViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        filters.isEmpty && results.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        results.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
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
        guard results.indices.contains(indexPath.item) else { return }

        collectionView.deselectItem(at: indexPath, animated: true)
        router.showDetail(for: results[indexPath.item])
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
        CGSize(width: collectionView.bounds.width, height: filters.isEmpty ? 0 : 56)
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

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard results.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: results.count
        ) else { return }

        let currentResultID = results[indexPath.item].id
        paginationTaskController.run { [weak self] in
            guard let self else { return }
            await viewModel.loadNextPageIfNeeded(currentResultID: currentResultID)
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
