//
//  HomeSectionListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/9.
//

import Observation
import UIKit

// MARK: - HomeSectionListViewController

@MainActor
final class HomeSectionListViewController: BaseListViewController {

    // MARK: - Properties

    private let category: MainHomeContentCategory
    private let viewModel: HomeSectionListViewModel
    private lazy var router: MainHomeRouting = MainHomeRouter(sourceViewController: self)
    private var items: [MainHomeContentItem] = []
    private var loadTask: Task<Void, Never>?
    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - Initialization

    init(category: MainHomeContentCategory) {
        self.category = category
        self.viewModel = HomeSectionListViewModel(category: category)
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    init(
        category: MainHomeContentCategory,
        viewModel: HomeSectionListViewModel
    ) {
        self.category = category
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.largeTitleDisplayMode = .never
        title = category.title
        configureCollectionView()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadInitialContent()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionViewFlowLayout.invalidateLayout()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = MovieGridLayoutMetrics.itemSpacing
        collectionView.register(
            HomeSectionListItemCollectionViewCell.self,
            forCellWithReuseIdentifier: HomeSectionListItemCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        cancelLoadNextPageTask()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitial()
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

    private func render(state: HomeSectionListViewState) {
        switch state {
        case .idle, .loading:
            items = []
            setLoadingVisible(state == .loading)
            collectionView.backgroundView = nil

        case .empty:
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: .emptyContent)

        case .failed(let errorMessage):
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: errorMessage) { [weak self] in
                self?.loadInitialContent()
            }

        case .loaded(let content):
            items = content.items
            setLoadingVisible(false)
            collectionView.backgroundView = nil
        }

        collectionView.reloadData()
    }

    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        guard !paginationTaskController.isRunning else { return }

        guard MovieGridLayoutMetrics.shouldLoadNextPage(
            currentIndex: indexPath.item,
            itemCount: items.count
        ) else {
            return
        }

        let currentItemID = items[indexPath.item].id

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            switch viewModel.state {
            case .loaded:
                await viewModel.loadNextPageIfNeeded(currentItemID: currentItemID)

            case .idle, .loading, .empty, .failed:
                break
            }
        }
    }

    private func cancelLoadNextPageTask() {
        paginationTaskController.cancel()
    }
}

// MARK: - UICollectionViewDataSource

extension HomeSectionListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: HomeSectionListItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? HomeSectionListItemCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(
                with: items[indexPath.item],
                imageHeight: MovieGridLayoutMetrics.posterHeight(for: collectionView.bounds.width)
            )
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension HomeSectionListViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
