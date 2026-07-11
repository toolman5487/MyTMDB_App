//
//  MainTVListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListRouting

@MainActor
protocol MainTVListRouting: AnyObject {
    var shouldIgnoreSearchCancellation: Bool { get }

    func showTVDetail(seriesID: Int)
    func showTVDetailFromSearch(
        seriesID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    )
    func showGenrePageSheet(
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - MainTVListRouter

@MainActor
final class MainTVListRouter: BaseRouter, MainTVListRouting {

    // MARK: - Properties

    private(set) var isDismissingSearchForNavigation = false

    var shouldIgnoreSearchCancellation: Bool {
        isDismissingSearchForNavigation
    }

    // MARK: - Push

    func showTVDetail(seriesID: Int) {
        guard seriesID > 0 else { return }
        show(TVDetailViewController(seriesID: seriesID), using: .push)
    }

    func showTVDetailFromSearch(
        seriesID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    ) {
        guard seriesID > 0,
              let sourceViewController,
              let navigationController = sourceViewController.navigationController else {
            return
        }

        isDismissingSearchForNavigation = true
        searchController.searchBar.resignFirstResponder()

        let finishSearchCleanup = { [weak self] in
            guard let self else { return }

            if searchController.isActive {
                searchController.isActive = false
            }

            isDismissingSearchForNavigation = false
            onSearchDismissed()
        }

        show(TVDetailViewController(seriesID: seriesID), using: .push)

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard !context.isCancelled else {
                    self?.isDismissingSearchForNavigation = false
                    return
                }

                finishSearchCleanup()
            }
        } else {
            Task(priority: .userInitiated) { @MainActor in
                finishSearchCleanup()
            }
        }
    }

    // MARK: - Page Sheet

    func showGenrePageSheet(
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainTVGenrePageSheetViewController(
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }
}

// MARK: - MainTVGenrePageSheetViewController

@MainActor
private final class MainTVGenrePageSheetViewController: UICollectionViewController {

    // MARK: - Constants

    private enum CellIdentifier {
        static let genre = String(describing: MainTVGenrePageSheetCell.self)
    }

    private enum Layout {
        static let columnCount: CGFloat = 3
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHeight: CGFloat = 48
        static let sectionTopInset: CGFloat = 16
        static let sectionBottomInset: CGFloat = 24
    }

    // MARK: - Properties

    private let filters: [MainTVGenreItem]
    private let onFilterSelected: (Int) -> Void
    private let onDismiss: () -> Void

    // MARK: - Initialization

    init(
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.filters = filters
        self.onFilterSelected = onFilterSelected
        self.onDismiss = onDismiss
        super.init(collectionViewLayout: Self.makeLayout())
    }

    required init?(coder: NSCoder) {
        self.filters = []
        self.onFilterSelected = { _ in }
        self.onDismiss = {}
        super.init(coder: coder)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureCollectionView()
        configureNavigationItem()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        if isBeingDismissed || navigationController?.isBeingDismissed == true {
            onDismiss()
        }
    }

    // MARK: - Setup

    private func configureView() {
        title = "劇集種類"
        view.backgroundColor = ThemeColor.background
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = ThemeColor.background
        collectionView.register(
            MainTVGenrePageSheetCell.self,
            forCellWithReuseIdentifier: CellIdentifier.genre
        )
    }

    private func configureNavigationItem() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            systemItem: .close,
            primaryAction: UIAction { [weak self] _ in
                self?.dismiss(animated: true)
            }
        )
    }

    private static func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: Layout.sectionTopInset,
            left: Layout.horizontalInset,
            bottom: Layout.sectionBottomInset,
            right: Layout.horizontalInset
        )
        return layout
    }

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CellIdentifier.genre,
            for: indexPath
        )
        (cell as? MainTVGenrePageSheetCell)?.configure(with: filters[indexPath.item])
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onFilterSelected(filters[indexPath.item].id)
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainTVGenrePageSheetViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = Layout.itemSpacing * (Layout.columnCount - 1)
        let horizontalInsets = Layout.horizontalInset * 2
        let width = (collectionView.bounds.width - horizontalInsets - totalSpacing) / Layout.columnCount

        return CGSize(
            width: floor(max(width, 0)),
            height: Layout.itemHeight
        )
    }
}

// MARK: - MainTVGenrePageSheetCell

@MainActor
private final class MainTVGenrePageSheetCell: BaseFilterHeaderCollectionViewCell {

    override func configureView() {
        super.configureView()
        applyTextPillStyle(.genrePageSheet)
    }

    // MARK: - Configuration

    func configure(with item: MainTVGenreItem) {
        configure(
            title: item.name,
            isSelected: item.isSelected
        )
    }
}
