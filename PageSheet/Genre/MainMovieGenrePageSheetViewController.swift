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
private final class MainMovieGenrePageSheetCell: UICollectionViewCell {

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        contentView.backgroundColor = ThemeColor.backgroundTertiary
        contentView.layer.borderColor = ThemeColor.highlight.withAlphaComponent(0.36).cgColor
    }

    // MARK: - Setup

    private func configureView() {
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 2
    }

    private func setupHierarchy() {
        contentView.addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    // MARK: - Configuration

    func configure(with item: MainMovieGenreItem) {
        titleLabel.text = item.name
        titleLabel.textColor = item.isSelected ? .white : ThemeColor.textPrimary
        contentView.backgroundColor = item.isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        contentView.layer.borderColor = borderColor(isSelected: item.isSelected).cgColor
    }

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
    }
}
