//
//  MainMovieSearchResultsViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - MainMovieSearchResultsViewController

@MainActor
final class MainMovieSearchResultsViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MainMovieSearchResultsViewModel

    var onMovieSelected: ((Int) -> Void)?
    var onSortBarButtonVisibilityChanged: ((Bool, MovieSortOption?) -> Void)?

    private var movies: [MovieGridMovieItem] = []
    private var canLoadNextPage = false
    private var isLoadingNextPage = false
    private var searchTask: Task<Void, Never>?
    private var loadNextPageTask: Task<Void, Never>?
    private var loadNextPageGeneration = 0

    // MARK: - UI Components

    private lazy var collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = .zero
        layout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        layout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
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
            MainMovieSearchResultCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMovieSearchResultCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

    init(viewModel: MainMovieSearchResultsViewModel = MainMovieSearchResultsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainMovieSearchResultsViewModel()
        super.init(coder: coder)
    }

    deinit {
        searchTask?.cancel()
        loadNextPageTask?.cancel()
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

    // MARK: - Rendering

    func showTypingLoading() {
        searchTask?.cancel()
        viewModel.showTypingLoading()
        renderCurrentState()
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
        renderCurrentState()

        searchTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            await viewModel.searchMovies(keyword: trimmedKeyword)

            guard !Task.isCancelled else { return }
            renderCurrentState()
        }
    }

    func selectSortOption(_ option: MovieSortOption) {
        viewModel.selectSortOption(option)
        renderCurrentState()
    }

    func reset() {
        searchTask?.cancel()
        cancelLoadNextPageTask()
        viewModel.reset()
        renderCurrentState()
    }

    private func renderCurrentState() {
        render(state: viewModel.state)
        updateSortBarButtonVisibility(for: viewModel.state)
    }

    private func render(state: MainMovieSearchResultsViewState) {
        switch state {
        case .idle:
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .typing:
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchTypingLoadingView()

        case .searching(let keyword):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchSubmittedLoadingView(keyword: keyword)

        case .results(let content):
            movies = content.movies
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .empty(let keyword):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "找不到電影",
                    message: "沒有符合「\(keyword)」的搜尋結果",
                    systemImageName: "magnifyingglass"
                )
            )

        case .failed(let errorMessage):
            movies = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(message: errorMessage)
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMovieSearchResultsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        movies.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        movies.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainMovieSearchResultCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainMovieSearchResultCollectionViewCell,
           movies.indices.contains(indexPath.item) {
            cell.configure(
                with: movies[indexPath.item],
                imageHeight: MovieGridLayoutMetrics.posterHeight(for: collectionView.bounds.width)
            )
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMovieSearchResultsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        let movieID = movies[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        onMovieSelected?(movieID)
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
        MovieGridLayoutMetrics.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: 16,
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

// MARK: - Private Methods

private extension MainMovieSearchResultsViewController {

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard movies.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard loadNextPageTask == nil else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: movies.count
        ) else { return }

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

            await viewModel.loadNextPageIfNeeded(currentMovieID: currentMovieID)

            guard !Task.isCancelled, loadNextPageGeneration == generation else { return }
            renderCurrentState()
        }
    }

    func cancelLoadNextPageTask() {
        loadNextPageGeneration += 1
        loadNextPageTask?.cancel()
        loadNextPageTask = nil
    }

    func updateSortBarButtonVisibility(for state: MainMovieSearchResultsViewState) {
        switch state {
        case .results(let content):
            onSortBarButtonVisibilityChanged?(true, content.selectedSortOption)

        case .idle, .typing, .searching, .empty, .failed:
            onSortBarButtonVisibilityChanged?(false, nil)
        }
    }
}
