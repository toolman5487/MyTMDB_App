//
//  MovieDetailReviewViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import SnapKit
import UIKit

@MainActor
final class MovieReviewListViewController: ScrollTrackingBaseViewController {

    // MARK: - Properties

    private let movieID: Int
    private let viewModel: MovieDetailReviewViewModel
    private lazy var router: MovieReviewListRouting = MovieReviewListRouter(sourceViewController: self)

    private var filters: [MovieDetailReviewFilterItem] = []
    private var reviews: [MovieDetailReviewItem] = []

    private var hasNextPage = false
    private var isLoadingNextPage = false

    private var loadTask: Task<Void, Never>?

    private let paginationTaskController = MovieGridPaginationTaskController()

    // MARK: - Initialization

    convenience init(movieID: Int) {
        self.init(
            movieID: movieID,
            viewModel: MovieDetailReviewViewModel()
        )
    }

    init(
        movieID: Int,
        viewModel: MovieDetailReviewViewModel
    ) {
        self.movieID = movieID
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.movieID = 0
        self.viewModel = MovieDetailReviewViewModel()
        super.init(coder: coder)
    }

    deinit {
        loadTask?.cancel()
    }

    // MARK: - Layout

    private enum Layout {
        static let filterHeaderHeight: CGFloat = 56
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
        static let sectionTopInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
        static let loadingFooterHeight: CGFloat = 48
        static let paginationThreshold = 3
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = "評論"
        configureNavigationBarAppearance()
        configureCollectionView()
    }

    override func bindViewModel() {
        loadReviews()
    }

    override var collectionViewItemHeight: CGFloat {
        120
    }

    // MARK: - Setup

    private func configureNavigationBarAppearance() {
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
    }

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.sectionHeadersPinToVisibleBounds = true
        collectionViewFlowLayout.minimumLineSpacing = Layout.itemSpacing
        collectionViewFlowLayout.sectionInset = .zero

        collectionView.register(
            MovieDetailReviewCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailReviewCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            MovieDetailReviewFilterHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: MovieDetailReviewFilterHeaderView.reuseIdentifier
        )
        collectionView.register(
            MovieDetailReviewLoadingFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: MovieDetailReviewLoadingFooterView.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadReviews() {
        loadTask?.cancel()
        paginationTaskController.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }

            render(state: .loading)
            await viewModel.loadReviews(movieID: movieID)

            guard !Task.isCancelled else { return }
            render(state: viewModel.state)
        }
    }

    private func render(state: MovieDetailReviewViewState) {
        switch state {
        case .idle:
            filters = []
            reviews = []
            hasNextPage = false
            isLoadingNextPage = false
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            filters = []
            reviews = []
            hasNextPage = false
            isLoadingNextPage = false
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let presentation):
            filters = presentation.filters
            reviews = presentation.reviews
            hasNextPage = presentation.hasNextPage
            isLoadingNextPage = presentation.isLoadingNextPage
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .empty:
            filters = makeFilterItems()
            reviews = []
            hasNextPage = false
            isLoadingNextPage = false
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "目前沒有評論",
                    message: "這個篩選條件下沒有可顯示的評論。",
                    systemImageName: "text.bubble"
                )
            )

        case .failed(let message):
            filters = []
            reviews = []
            hasNextPage = false
            isLoadingNextPage = false
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadReviews()
            }
        }

        collectionView.reloadData()
    }

    private func makeFilterItems() -> [MovieDetailReviewFilterItem] {
        MovieDetailReviewFilter.allCases.map {
            MovieDetailReviewFilterItem(
                filter: $0,
                selectedFilter: viewModel.selectedFilter
            )
        }
    }

    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard hasNextPage else { return }
        guard !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }

        let thresholdIndex = max(reviews.count - Layout.paginationThreshold, 0)
        guard indexPath.item >= thresholdIndex else { return }
        guard viewModel.beginLoadingNextPage() else { return }

        render(state: viewModel.state)

        paginationTaskController.run { [weak self] in
            guard let self else { return }

            await viewModel.loadNextPage(movieID: movieID)
            render(state: viewModel.state)
        }
    }

}

// MARK: - UICollectionViewDataSource

extension MovieReviewListViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        filters.isEmpty ? 0 : 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        reviews.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailReviewCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? MovieDetailReviewCollectionViewCell)?.configure(with: reviews[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            let reusableView = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: MovieDetailReviewLoadingFooterView.reuseIdentifier,
                for: indexPath
            )

            if let footerView = reusableView as? MovieDetailReviewLoadingFooterView {
                footerView.configure(isAnimating: isLoadingNextPage)
            }

            return reusableView
        }

        guard kind == UICollectionView.elementKindSectionHeader else {
            return UICollectionReusableView()
        }

        let reusableView = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: MovieDetailReviewFilterHeaderView.reuseIdentifier,
            for: indexPath
        )

        if let headerView = reusableView as? MovieDetailReviewFilterHeaderView {
            headerView.configure(filters: filters)
            headerView.onFilterSelected = { [weak self] filter in
                self?.viewModel.selectFilter(filter)
                self?.render(state: self?.viewModel.state ?? .idle)
            }
        }

        return reusableView
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MovieReviewListViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        router.showReviewDetail(for: reviews[indexPath.item])
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
        referenceSizeForFooterInSection section: Int
    ) -> CGSize {
        CGSize(
            width: collectionView.bounds.width,
            height: isLoadingNextPage ? Layout.loadingFooterHeight : 0
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: Layout.sectionTopInset,
            left: Layout.horizontalInset,
            bottom: Layout.sectionBottomInset,
            right: Layout.horizontalInset
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let width = collectionView.bounds.width
            - Layout.horizontalInset * 2
        let height = MovieDetailReviewCollectionViewCell.fittingHeight(
            for: reviews[indexPath.item],
            width: max(width, 0)
        )

        return CGSize(
            width: max(width, 0),
            height: height
        )
    }
}
