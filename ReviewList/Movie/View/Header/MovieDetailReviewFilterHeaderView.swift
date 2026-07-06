//
//  MovieDetailReviewFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - MovieDetailReviewFilterHeaderView

@MainActor
final class MovieDetailReviewFilterHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MovieDetailReviewFilterHeaderView.self)

    // MARK: - Properties

    private var filters: [MovieDetailReviewFilterItem] = []
    var onFilterSelected: ((MovieDetailReviewFilter) -> Void)?

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHorizontalInset: CGFloat = 16
        static let itemHeight: CGFloat = 36
    }

    // MARK: - UI Components

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Layout.horizontalInset,
            bottom: 0,
            right: Layout.horizontalInset
        )
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailReviewFilterCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailReviewFilterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        filters = []
        onFilterSelected = nil
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(filters: [MovieDetailReviewFilterItem]) {
        self.filters = filters
        collectionView.reloadData()
    }

    fileprivate static func filterItemSize(for title: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let width = (title as NSString).size(withAttributes: [.font: font]).width
            + Layout.itemHorizontalInset * 2

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }
}

// MARK: - UICollectionViewDataSource

extension MovieDetailReviewFilterHeaderView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailReviewFilterCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? MovieDetailReviewFilterCollectionViewCell)?.configure(with: filters[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MovieDetailReviewFilterHeaderView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onFilterSelected?(filters[indexPath.item].id)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        Self.filterItemSize(for: filters[indexPath.item].title)
    }
}
