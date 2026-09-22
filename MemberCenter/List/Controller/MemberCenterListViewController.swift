//
//  MemberCenterListViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MemberCenterListViewController

@MainActor
final class MemberCenterListViewController: BaseListViewController {

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let topInset: CGFloat = 16
        static let bottomInset: CGFloat = 32
        static let itemSpacing: CGFloat = 12
        static let columnCount: CGFloat = 3
        static let posterAspectRatio: CGFloat = 1.5
        private static let minimumTextHeight: CGFloat = 44
        private static let textVerticalSpacing: CGFloat = 4

        private static var textHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            let metadataHeight = ceil(UIFont.preferredFont(forTextStyle: .caption2).lineHeight)
            return max(
                minimumTextHeight,
                titleHeight + textVerticalSpacing + metadataHeight
            )
        }

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
    private let sceneBuilder: MemberCenterSceneBuilding
    private lazy var router: MemberCenterRouting = MemberCenterRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var items: [MemberCenterListItem] = []

    private var loadTask: Task<Void, Never>?
    private let paginationTaskController = MediaGridPaginationTaskController()

    // MARK: - Initialization

    init(
        viewModel: MemberCenterListViewModel,
        sceneBuilder: MemberCenterSceneBuilding,
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
        loadTask?.cancel()
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        navigationItem.title = viewModel.destination.title(localization: interfaceLocalization)
        navigationItem.largeTitleDisplayMode = .never
        configureCollectionView()
    }

    override func bindViewModel() {
        viewModel.bind { [weak self] state in
            self?.render(state: state)
        }
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
        paginationTaskController.cancel()
        loadTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await viewModel.loadInitialContent()
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
                    title: destination.emptyTitle(localization: interfaceLocalization),
                    message: interfaceLocalization.string(
                        "member_center.empty.message",
                        defaultValue: "There's nothing in this category yet."
                    ),
                    systemImageName: destination.systemImageName
                ),
                localization: interfaceLocalization
            )

        case .failed(let message):
            items = []
            setLoadingVisible(false)
            collectionView.backgroundView = ErrorMessageView(
                message: message,
                localization: interfaceLocalization
            ) { [weak self] in
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
}
