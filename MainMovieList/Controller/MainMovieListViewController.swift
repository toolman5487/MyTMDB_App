//
//  MainMovieListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import UIKit

// MARK: - MainMovieListViewController

@MainActor
final class MainMovieListViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
        static let movieColumnCount: CGFloat = 3
        static let moviePosterAspectRatio: CGFloat = 1.5
        static let movieTextHeight: CGFloat = 40
        static let paginationThreshold = 4
    }

    // MARK: - Properties

    private let viewModel: MainMovieListViewModel
    private lazy var router: MainMovieListRouting = MainMovieListRouter(sourceViewController: self)
    private var filters: [MainMovieGenreItem] = []
    private var movies: [MainMovieListMovieItem] = []
    private var isFilterSkeletonVisible = true
    private var isFilterPageSheetPresented = false
    private var loadTask: Task<Void, Never>?
    private var searchTask: Task<Void, Never>?
    private var filterSelectionTask: Task<Void, Never>?
    private var loadNextPageTask: Task<Void, Never>?
    private var loadNextPageGeneration = 0

    // MARK: - UI Components

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "搜尋電影"
        searchController.obscuresBackgroundDuringPresentation = false
        return searchController
    }()

    private lazy var searchFilterBarButtonItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal.decrease.circle"),
            style: .plain,
            target: nil,
            action: nil
        )
        item.accessibilityLabel = "搜尋篩選"
        item.tintColor = ThemeColor.highlight
        return item
    }()

    private lazy var searchFilterButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        button.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        button.tintColor = ThemeColor.highlight
        button.accessibilityLabel = "搜尋篩選"
        button.showsMenuAsPrimaryAction = true
        return button
    }()

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
        searchTask?.cancel()
        filterSelectionTask?.cancel()
        loadNextPageTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureNavigationBarAppearance()
        configureCollectionView()
        configureSearchBar()
    }

    override func bindViewModel() {
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
        appearance.shadowColor = nil
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
        collectionViewFlowLayout.minimumLineSpacing = Layout.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = Layout.itemSpacing
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
        searchController.searchBar.searchTextField.rightViewMode = .never
        definesPresentationContext = true
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        cancelLoadNextPageTask()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadInitialContent()

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func selectFilter(id: Int) {
        filterSelectionTask?.cancel()
        cancelLoadNextPageTask()
        filterSelectionTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            await viewModel.selectGenre(id: id)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: MainMovieListViewState) {
        switch state {
        case .idle, .loading:
            filters = []
            movies = []
            isFilterSkeletonVisible = true
            updateSearchFilterButton(selectedFilter: nil)

        case .empty, .failed:
            filters = []
            movies = []
            isFilterSkeletonVisible = false
            updateSearchFilterButton(selectedFilter: nil)

        case .searchResults(let content):
            filters = []
            movies = content.movies
            isFilterSkeletonVisible = false
            updateSearchFilterButton(selectedFilter: content.selectedFilter)

        case .loaded(let content):
            filters = content.genres
            movies = content.movies
            isFilterSkeletonVisible = false
            navigationItem.title = "\(content.selectedGenre.name)電影"
            updateSearchFilterButton(selectedFilter: nil)
        }

        collectionView.reloadData()
    }

    // MARK: - Search

    private func submitSearch(keyword: String?) {
        searchTask?.cancel()
        cancelLoadNextPageTask()
        searchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.searchMovies(keyword: keyword ?? "")

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func selectSearchFilter(_ filter: MainMovieSearchFilter) {
        viewModel.selectSearchFilter(filter)
        render(state: viewModel.state)
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
                imageHeight: moviePosterHeight(in: collectionView)
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
        collectionView.deselectItem(at: indexPath, animated: true)
        router.showMovieDetail(movieID: movies[indexPath.item].id)
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
        let itemWidth = movieItemWidth(in: collectionView)

        return CGSize(
            width: itemWidth,
            height: moviePosterHeight(in: collectionView) + Layout.movieTextHeight
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        guard !isFilterSkeletonVisible else { return .zero }

        return UIEdgeInsets(
            top: 12,
            left: Layout.horizontalInset,
            bottom: 24,
            right: Layout.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.itemSpacing
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        Layout.itemSpacing
    }
}

// MARK: - UISearchResultsUpdating

extension MainMovieListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {}
}

// MARK: - UISearchBarDelegate

extension MainMovieListViewController: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        submitSearch(keyword: searchBar.text)
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        submitSearch(keyword: nil)
    }
}

// MARK: - Page Sheet

private extension MainMovieListViewController {

    var shouldShowContentSection: Bool {
        shouldShowFilterHeader || !movies.isEmpty
    }

    var shouldShowFilterHeader: Bool {
        isFilterSkeletonVisible || !filters.isEmpty
    }

    func movieItemWidth(in collectionView: UICollectionView) -> CGFloat {
        let totalHorizontalInsets = Layout.horizontalInset * 2
        let totalItemSpacing = Layout.itemSpacing * (Layout.movieColumnCount - 1)
        let availableWidth = collectionView.bounds.width - totalHorizontalInsets - totalItemSpacing

        return floor(max(availableWidth, 0) / Layout.movieColumnCount)
    }

    func moviePosterHeight(in collectionView: UICollectionView) -> CGFloat {
        movieItemWidth(in: collectionView) * Layout.moviePosterAspectRatio
    }

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        guard loadNextPageTask == nil else { return }

        let thresholdIndex = max(movies.count - Layout.paginationThreshold, 0)
        guard indexPath.item >= thresholdIndex else { return }

        let currentMovieID = movies[indexPath.item].id
        loadNextPageGeneration += 1
        let generation = loadNextPageGeneration

        loadNextPageTask = Task(priority: .utility) { [weak self] in
            guard let self else { return }
            defer {
                if loadNextPageGeneration == generation {
                    loadNextPageTask = nil
                }
            }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentMovieID: currentMovieID)

            case .searchResults:
                await viewModel.loadNextSearchPageIfNeeded(currentMovieID: currentMovieID)

            case .idle, .loading, .empty, .failed:
                break
            }

            guard !Task.isCancelled, loadNextPageGeneration == generation else { return }
            render(state: viewModel.state)
        }
    }

    func cancelLoadNextPageTask() {
        loadNextPageGeneration += 1
        loadNextPageTask?.cancel()
        loadNextPageTask = nil
    }

    func updateSearchFilterButton(selectedFilter: MainMovieSearchFilter?) {
        guard let selectedFilter else {
            navigationItem.rightBarButtonItem = nil
            searchController.searchBar.searchTextField.rightView = nil
            searchController.searchBar.searchTextField.rightViewMode = .never
            return
        }

        let menu = makeSearchFilterMenu(selectedFilter: selectedFilter)
        searchFilterBarButtonItem.menu = menu
        searchFilterButton.menu = menu
        searchController.searchBar.searchTextField.rightView = searchFilterButton
        searchController.searchBar.searchTextField.rightViewMode = .always
        navigationItem.rightBarButtonItem = searchFilterBarButtonItem
    }

    func makeSearchFilterMenu(selectedFilter: MainMovieSearchFilter) -> UIMenu {
        let actions = MainMovieSearchFilter.allCases.map { filter in
            UIAction(
                title: filter.title,
                state: filter == selectedFilter ? .on : .off
            ) { [weak self] _ in
                self?.selectSearchFilter(filter)
            }
        }

        return UIMenu(title: "搜尋篩選", options: .singleSelection, children: actions)
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
