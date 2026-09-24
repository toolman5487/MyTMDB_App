//
//  DetailContentListViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import UIKit

// MARK: - DetailContentListViewController

@MainActor
final class DetailContentListViewController: BaseListViewController {

    // MARK: - Properties

    private let configuration: DetailContentListConfiguration
    private let pageProvider: (any DetailContentListPageProviding)?
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: DetailContentListRouting = DetailContentListRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

    private var items: [DetailContentListItem]
    private var canLoadNextPage: Bool
    private var isLoadingNextPage = false
    private let paginationTaskController = MediaGridPaginationTaskController()

    // MARK: - Override Points

    override var fallbackCollectionViewItemHeight: CGFloat {
        switch configuration.thumbnailStyle {
        case .portrait, .landscape:
            return 112

        case .gallery:
            let imageWidth = max(
                collectionView.bounds.width - (DetailLayoutMetrics.horizontalContentInset * 2),
                0
            )
            return max((imageWidth * 9 / 16) + 16, 160)
        }
    }

    // MARK: - Initialization

    init(
        configuration: DetailContentListConfiguration,
        pageProvider: (any DetailContentListPageProviding)? = nil,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.configuration = configuration
        self.pageProvider = pageProvider
        self.items = configuration.items
        self.canLoadNextPage = pageProvider != nil
        self.sceneBuilder = sceneBuilder
        super.init(nibName: nil, bundle: nil)
        setInterfaceLocalization(interfaceLocalization)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        title = configuration.title
        view.backgroundColor = ThemeColor.background
        AppFactory.NavigationBar.applyStandardAppearance(to: navigationItem)
        configureCollectionView()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.backgroundColor = ThemeColor.background
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsVerticalScrollIndicator = false
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionView.register(
            DetailContentListRowCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailContentListRowCollectionViewCell.reuseIdentifier
        )
        collectionView.register(
            DetailContentListGalleryCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailContentListGalleryCollectionViewCell.reuseIdentifier
        )
    }

    // MARK: - Pagination

    private func loadNextPageIfNeeded(currentIndex: Int) {
        guard let pageProvider, canLoadNextPage, !isLoadingNextPage else { return }
        guard !paginationTaskController.isRunning else { return }
        guard MediaGridPaginationState.shouldLoadNextPage(
            currentIndex: currentIndex,
            itemCount: items.count
        ) else { return }

        isLoadingNextPage = true

        paginationTaskController.run { [weak self] in
            guard let self else { return }
            defer { isLoadingNextPage = false }

            do {
                let page = try await pageProvider.loadNextPage()
                guard !Task.isCancelled else { return }

                let existingIDs = Set(items.map(\.id))
                let newItems = page.items.filter { !existingIDs.contains($0.id) }
                let insertedIndexPaths = (items.count..<(items.count + newItems.count))
                    .map { IndexPath(item: $0, section: 0) }

                items.append(contentsOf: newItems)
                canLoadNextPage = page.canLoadNextPage

                guard !insertedIndexPaths.isEmpty else { return }
                collectionView.insertItems(at: insertedIndexPaths)
            } catch {
                guard !Task.isCancelled else { return }
                canLoadNextPage = false
            }
        }
    }
}

// MARK: - UICollectionViewDataSource

extension DetailContentListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard items.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.item]

        switch configuration.thumbnailStyle {
        case .portrait, .landscape:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DetailContentListRowCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? DetailContentListRowCollectionViewCell)?.configure(
                with: item,
                thumbnailStyle: configuration.thumbnailStyle,
                localization: interfaceLocalization
            )
            return cell

        case .gallery:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: DetailContentListGalleryCollectionViewCell.reuseIdentifier,
                for: indexPath
            )
            (cell as? DetailContentListGalleryCollectionViewCell)?.configure(
                with: item,
                localization: interfaceLocalization
            )
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate

extension DetailContentListViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        router.showDestination(
            items[indexPath.item].destination,
            configuration: configuration
        )
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        loadNextPageIfNeeded(currentIndex: indexPath.item)
    }
}
