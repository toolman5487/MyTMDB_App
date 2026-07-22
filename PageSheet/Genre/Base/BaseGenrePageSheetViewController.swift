//
//  BaseGenrePageSheetViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import UIKit

// MARK: - GenrePageSheetItemRepresentable

nonisolated protocol GenrePageSheetItemRepresentable: Sendable, Identifiable where ID == Int {
    var name: String { get }
    var isSelected: Bool { get }
}

// MARK: - BaseGenrePageSheetLayout

@MainActor
private enum BaseGenrePageSheetLayout {
    static var cellReuseIdentifier: String {
        String(describing: BaseGenrePageSheetCell.self)
    }

    static let columnCount: CGFloat = 3
    static let horizontalInset: CGFloat = 16
    static let itemSpacing: CGFloat = 8
    static let itemHeight: CGFloat = 48
    static let sectionTopInset: CGFloat = 16
    static let sectionBottomInset: CGFloat = 24

    static func makeCollectionViewLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = itemSpacing
        layout.minimumInteritemSpacing = itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: sectionTopInset,
            left: horizontalInset,
            bottom: sectionBottomInset,
            right: horizontalInset
        )
        return layout
    }
}

// MARK: - BaseGenrePageSheetViewController

@MainActor
class BaseGenrePageSheetViewController<Item: GenrePageSheetItemRepresentable>: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // MARK: - Properties

    private let pageTitle: String
    private let filters: [Item]
    private let onFilterSelected: (Int) -> Void
    private let onDismiss: () -> Void

    // MARK: - UI Components

    private let glassBackgroundView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: nil)
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()

    // MARK: - Initialization

    init(
        title: String,
        filters: [Item],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.pageTitle = title
        self.filters = filters
        self.onFilterSelected = onFilterSelected
        self.onDismiss = onDismiss
        super.init(collectionViewLayout: BaseGenrePageSheetLayout.makeCollectionViewLayout())
    }

    required init?(coder: NSCoder) {
        self.pageTitle = ""
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
        title = pageTitle
        view.backgroundColor = .clear
        glassBackgroundView.effect = GlassBackgroundEffect.make()
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.backgroundView = glassBackgroundView
        collectionView.register(
            BaseGenrePageSheetCell.self,
            forCellWithReuseIdentifier: BaseGenrePageSheetLayout.cellReuseIdentifier
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

    // MARK: - UICollectionViewDataSource

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: BaseGenrePageSheetLayout.cellReuseIdentifier,
            for: indexPath
        )
        (cell as? BaseGenrePageSheetCell)?.configure(with: filters[indexPath.item])
        return cell
    }

    // MARK: - UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onFilterSelected(filters[indexPath.item].id)
        dismiss(animated: true)
    }

    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let totalSpacing = BaseGenrePageSheetLayout.itemSpacing * (BaseGenrePageSheetLayout.columnCount - 1)
        let horizontalInsets = BaseGenrePageSheetLayout.horizontalInset * 2
        let width = (collectionView.bounds.width - horizontalInsets - totalSpacing) / BaseGenrePageSheetLayout.columnCount

        return CGSize(
            width: floor(max(width, 0)),
            height: BaseGenrePageSheetLayout.itemHeight
        )
    }
}

// MARK: - BaseGenrePageSheetCell

@MainActor
private final class BaseGenrePageSheetCell: BaseFilterHeaderCollectionViewCell {

    override func configureView() {
        super.configureView()
        applyTextPillStyle(.genrePageSheet)
    }

    // MARK: - Configuration

    func configure<Item: GenrePageSheetItemRepresentable>(with item: Item) {
        configure(
            title: BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: item.name),
            isSelected: item.isSelected
        )
    }
}
