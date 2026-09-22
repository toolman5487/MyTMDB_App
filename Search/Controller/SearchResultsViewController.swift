//
//  SearchResultsViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - SearchResultsHandling

@MainActor
protocol SearchResultsHandling: AnyObject {
    func showTypingLoading()
    func submitSearch(keyword: String)
    func selectSortOption(_ option: MediaSortOrder)
    func reset()
}

// MARK: - SearchResultsViewController

@MainActor
final class SearchResultsViewController: BaseViewController, SearchResultsHandling {

    // MARK: - Properties

    private let mediaKind: MediaKind
    private let viewModel: SearchResultsViewModel

    private let onItemSelected: @MainActor (Int) -> Void
    private let onSortBarButtonVisibilityChanged: @MainActor (Bool, MediaSortOrder?) -> Void

    private var items: [MediaGridItem] = []

    private var canLoadNextPage = false
    private var isLoadingNextPage = false

    private var searchTask: Task<Void, Never>?

    private let paginationTaskController = MediaGridPaginationTaskController()

    // MARK: - UI Components

    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.minimumLineSpacing = MediaGridLayoutMetrics.itemSpacing
        layout.minimumInteritemSpacing = MediaGridLayoutMetrics.itemSpacing
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            SearchResultCollectionViewCell.self,
            forCellWithReuseIdentifier: SearchResultCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

    init(
        mediaKind: MediaKind,
        viewModel: SearchResultsViewModel,
        onItemSelected: @escaping @MainActor (Int) -> Void,
        onSortBarButtonVisibilityChanged: @escaping @MainActor (Bool, MediaSortOrder?) -> Void,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.mediaKind = mediaKind
        self.viewModel = viewModel
        self.onItemSelected = onItemSelected
        self.onSortBarButtonVisibilityChanged = onSortBarButtonVisibilityChanged
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(interfaceLocalization)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTask?.cancel()
    }

    // MARK: - Template Methods

    override func configureView() {
        super.configureView()
        view.backgroundColor = ThemeColor.background
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        viewModel.bind { [weak self] state in
            self?.render(state: state)
            self?.updateSortBarButtonVisibility(for: state)
        }
    }

    // MARK: - Rendering

    func showTypingLoading() {
        searchTask?.cancel()
        viewModel.showTypingLoading()
    }

    func submitSearch(keyword: String) {
        searchTask?.cancel()
        cancelLoadNextPageTask()

        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKeyword.isEmpty else {
            reset()
            return
        }

        viewModel.showSearchLoading(keyword: trimmedKeyword)

        searchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            await viewModel.search(keyword: trimmedKeyword)
        }
    }

    func selectSortOption(_ option: MediaSortOrder) {
        viewModel.selectSortOption(option)
    }

    func reset() {
        searchTask?.cancel()
        cancelLoadNextPageTask()
        viewModel.reset()
    }

    private func render(state: SearchResultsViewState) {
        switch state {
        case .idle:
            items = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .typing:
            items = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = SearchTypingLoadingView(
                localization: interfaceLocalization
            )

        case .searching(let keyword):
            items = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = SearchSubmittedLoadingView(
                keyword: keyword,
                localization: interfaceLocalization
            )

        case .results(let content):
            items = content.items
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .empty(let keyword):
            items = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: mediaKind.searchEmptyTitle(localization: interfaceLocalization),
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
            items = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: errorMessage,
                localization: interfaceLocalization
            )
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension SearchResultsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        items.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SearchResultCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? SearchResultCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(
                with: items[indexPath.item],
                kind: mediaKind,
                imageHeight: MediaGridLayoutMetrics.posterHeight(for: collectionView.bounds.width),
                localization: interfaceLocalization
            )
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension SearchResultsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        let itemID = items[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        onItemSelected(itemID)
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
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        MediaGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 16,
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

// MARK: - Private Methods

private extension SearchResultsViewController {

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MediaGridPaginationState.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else { return }

        let currentItemID = items[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            await viewModel.loadNextPageIfNeeded(currentItemID: currentItemID)
        }
    }

    func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }

    func updateSortBarButtonVisibility(for state: SearchResultsViewState) {
        switch state {
        case .results(let content):
            onSortBarButtonVisibilityChanged(true, content.selectedSortOption)

        case .idle, .typing, .searching, .empty, .failed:
            onSortBarButtonVisibilityChanged(false, nil)
        }
    }
}

// MARK: - MediaKind Search Text

private extension MediaKind {

    func searchEmptyTitle(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("search.empty.movie.title", defaultValue: "No Movies Found")

        case .tv:
            return localization.string("search.empty.tv.title", defaultValue: "No TV Shows Found")
        }
    }
}
