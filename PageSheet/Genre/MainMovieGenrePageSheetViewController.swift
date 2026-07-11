//
//  MainMovieGenrePageSheetViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieGenrePageSheetViewController

@MainActor
final class MainMovieGenrePageSheetViewController: UICollectionViewController {

    // MARK: - Constants

    private enum CellIdentifier {
        static let genre = String(describing: MainMovieGenrePageSheetCell.self)
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

    private let filters: [MainMovieGenreItem]
    private let onFilterSelected: (Int) -> Void
    private let onDismiss: () -> Void

    // MARK: - Initialization

    init(
        filters: [MainMovieGenreItem],
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
        title = "電影種類"
        view.backgroundColor = ThemeColor.background
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = ThemeColor.background
        collectionView.register(
            MainMovieGenrePageSheetCell.self,
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
        (cell as? MainMovieGenrePageSheetCell)?.configure(with: filters[indexPath.item])
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

extension MainMovieGenrePageSheetViewController: UICollectionViewDelegateFlowLayout {

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

// MARK: - MainMovieGenrePageSheetCell

@MainActor
private final class MainMovieGenrePageSheetCell: BaseFilterHeaderCollectionViewCell {

    override func configureView() {
        super.configureView()
        applyTextPillStyle(.genrePageSheet)
    }

    // MARK: - Configuration

    func configure(with item: MainMovieGenreItem) {
        configure(
            title: item.name,
            isSelected: item.isSelected
        )
    }
}
