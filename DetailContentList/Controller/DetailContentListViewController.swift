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
    private let sceneBuilder: DetailSceneBuilding
    private lazy var router: DetailContentListRouting = DetailContentListRouter(
        sourceViewController: self,
        sceneBuilder: sceneBuilder,
        interfaceLocalization: interfaceLocalization
    )

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
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.configuration = configuration
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
}

// MARK: - UICollectionViewDataSource

extension DetailContentListViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        configuration.items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard configuration.items.indices.contains(indexPath.item) else {
            return UICollectionViewCell()
        }

        let item = configuration.items[indexPath.item]

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
        guard configuration.items.indices.contains(indexPath.item) else { return }
        collectionView.deselectItem(at: indexPath, animated: true)
        router.showDestination(
            configuration.items[indexPath.item].destination,
            configuration: configuration
        )
    }
}
