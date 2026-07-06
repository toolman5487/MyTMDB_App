//
//  MainTVSearchResultsViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - MainTVSearchResultsViewController

@MainActor
final class MainTVSearchResultsViewController: BaseViewController {

    // MARK: - Properties

    private let viewModel: MainTVSearchResultsViewModel

    var onSeriesSelected: ((Int) -> Void)?
    var onSortBarButtonVisibilityChanged: ((Bool, TVSortOption?) -> Void)?

    private var series: [TVGridSeriesItem] = []
    private var canLoadNextPage = false
    private var isLoadingNextPage = false
    private var searchTask: Task<Void, Never>?
    private let paginationTaskController = MovieGridPaginationTaskController()

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
            MainTVSearchResultCollectionViewCell.self,
            forCellWithReuseIdentifier: MainTVSearchResultCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

    init(viewModel: MainTVSearchResultsViewModel = MainTVSearchResultsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.viewModel = MainTVSearchResultsViewModel()
        super.init(coder: coder)
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

            await viewModel.searchSeries(keyword: trimmedKeyword)

            guard !Task.isCancelled else { return }
            renderCurrentState()
        }
    }

    func selectSortOption(_ option: TVSortOption) {
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

    private func render(state: MainTVSearchResultsViewState) {
        switch state {
        case .idle:
            series = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = nil

        case .typing:
            series = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchTypingLoadingView()

        case .searching(let keyword):
            series = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = MainMovieSearchSubmittedLoadingView(keyword: keyword)

        case .results(let content):
            series = content.series
            canLoadNextPage = content.canLoadNextPage
            isLoadingNextPage = content.isLoadingNextPage
            collectionView.backgroundView = nil

        case .empty(let keyword):
            series = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "找不到劇集",
                    message: "沒有符合「\(keyword)」的搜尋結果",
                    systemImageName: "magnifyingglass"
                )
            )

        case .failed(let errorMessage):
            series = []
            canLoadNextPage = false
            isLoadingNextPage = false
            collectionView.backgroundView = ErrorMessageView(message: errorMessage)
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainTVSearchResultsViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        series.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        series.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainTVSearchResultCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainTVSearchResultCollectionViewCell,
           series.indices.contains(indexPath.item) {
            cell.configure(
                with: series[indexPath.item],
                imageHeight: MovieGridLayoutMetrics.posterHeight(for: collectionView.bounds.width)
            )
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainTVSearchResultsViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard series.indices.contains(indexPath.item) else { return }
        let seriesID = series[indexPath.item].id

        collectionView.deselectItem(at: indexPath, animated: true)
        onSeriesSelected?(seriesID)
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

private extension MainTVSearchResultsViewController {

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard series.indices.contains(indexPath.item) else { return }
        guard canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: series.count
        ) else { return }

        let currentSeriesID = series[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            await viewModel.loadNextPageIfNeeded(currentSeriesID: currentSeriesID)
            renderCurrentState()
        }
    }

    func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }

    func updateSortBarButtonVisibility(for state: MainTVSearchResultsViewState) {
        switch state {
        case .results(let content):
            onSortBarButtonVisibilityChanged?(true, content.selectedSortOption)

        case .idle, .typing, .searching, .empty, .failed:
            onSortBarButtonVisibilityChanged?(false, nil)
        }
    }
}
