//
//  MemberCenterListViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Observation
import UIKit

// MARK: - MemberCenterListViewController

@MainActor
final class MemberCenterListViewController: MainBaseViewController {

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 16
        static let bottomInset: CGFloat = 32
        static let itemSpacing: CGFloat = 12
        static let textHeight: CGFloat = 44
        static let columnCount: CGFloat = 3
        static let posterAspectRatio: CGFloat = 1.5
        static let paginationThreshold = 4

        static func itemSize(for collectionViewWidth: CGFloat) -> CGSize {
            let totalHorizontalInsets = horizontalInset * 2
            let totalItemSpacing = itemSpacing * (columnCount - 1)
            let availableWidth = collectionViewWidth - totalHorizontalInsets - totalItemSpacing
            let itemWidth = floor(max(availableWidth, 0) / columnCount)

            return CGSize(
                width: itemWidth,
                height: (itemWidth * posterAspectRatio) + textHeight
            )
        }
    }

    // MARK: - Properties

    private let viewModel: MemberCenterListViewModel
    private lazy var router: MemberCenterRouting = MemberCenterRouter(sourceViewController: self)
    private var items: [MemberCenterListItem] = []
    private var loadTask: Task<Void, Never>?
    private var loadNextPageTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        destination: MemberCenterDestination,
        accountId: Int,
        sessionId: String,
        service: MemberCenterServicing = MemberCenterService()
    ) {
        self.viewModel = MemberCenterListViewModel(
            destination: destination,
            accountId: accountId,
            sessionId: sessionId,
            service: service
        )
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    init(viewModel: MemberCenterListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        self.viewModel = MemberCenterListViewModel(
            destination: .favoriteMovies,
            accountId: 0,
            sessionId: ""
        )
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    deinit {
        loadTask?.cancel()
        loadNextPageTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.title = viewModel.destination.title
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        render(state: viewModel.state)
        observeViewModelState()
        loadInitialContent()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = Layout.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = Layout.itemSpacing
        collectionView.register(
            MemberCenterListItemCollectionViewCell.self,
            forCellWithReuseIdentifier: MemberCenterListItemCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Data Loading

    private func loadInitialContent() {
        loadTask?.cancel()
        loadNextPageTask?.cancel()
        loadNextPageTask = nil
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent()
        }
    }

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

    private func render(state: MemberCenterListViewState) {
        switch state {
        case .idle:
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .loading:
            items = []
            setLoadingVisible(true)
            collectionView.backgroundView = nil

        case .loaded(let content):
            items = content.items
            setLoadingVisible(false)
            collectionView.backgroundView = nil

        case .empty(let destination):
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(
                message: ErrorMessage(
                    title: "沒有\(destination.title)",
                    message: "這個分類目前沒有內容。",
                    systemImageName: destination.systemImageName
                )
            )

        case .failed(let message):
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(message: message) { [weak self] in
                self?.loadInitialContent()
            }
        }

        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MemberCenterListViewController: UICollectionViewDataSource {

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
            withReuseIdentifier: MemberCenterListItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MemberCenterListItemCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MemberCenterListViewController: UICollectionViewDelegateFlowLayout {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        beginTabBarVisibilityTracking(for: scrollView)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateTabBarVisibilityTracking(for: scrollView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard items.indices.contains(indexPath.item) else { return }
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
        Layout.itemSize(for: collectionView.bounds.width)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        UIEdgeInsets(
            top: Layout.topInset,
            left: Layout.horizontalInset,
            bottom: Layout.bottomInset,
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

// MARK: - Private Methods

private extension MemberCenterListViewController {

    func loadNextPageIfNeeded(for indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        guard loadNextPageTask == nil else { return }

        let thresholdIndex = max(items.count - Layout.paginationThreshold, 0)
        guard indexPath.item >= thresholdIndex else { return }

        let currentItemID = items[indexPath.item].id

        loadNextPageTask = Task(priority: .utility) { @MainActor [weak self] in
            guard let self else { return }

            defer {
                loadNextPageTask = nil
            }

            await viewModel.loadNextPageIfNeeded(currentItemID: currentItemID)
        }
    }
}
