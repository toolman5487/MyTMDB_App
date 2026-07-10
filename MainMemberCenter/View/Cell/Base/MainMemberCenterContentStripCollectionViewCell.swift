//
//  MainMemberCenterContentStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SnapKit
import UIKit

// MARK: - MainMemberCenterContentStripCollectionViewCell

@MainActor
class MainMemberCenterContentStripCollectionViewCell: BaseCollectionViewCell {

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
    }

    private var items: [MainMemberCenterListItem] = []
    private var onItemSelected: ((MainMemberCenterListItem) -> Void)?

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
        layout.itemSize = CGSize(
            width: Layout.posterWidth,
            height: Layout.itemHeight
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
            MainMemberCenterListItemCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMemberCenterListItemCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func resetForReuse() {
        items = []
        onItemSelected = nil
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    func configure(
        items: [MainMemberCenterListItem],
        onItemSelected: @escaping (MainMemberCenterListItem) -> Void
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMemberCenterContentStripCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainMemberCenterListItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainMemberCenterListItemCollectionViewCell,
           items.indices.contains(indexPath.item) {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainMemberCenterContentStripCollectionViewCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard items.indices.contains(indexPath.item) else { return }
        onItemSelected?(items[indexPath.item])
    }
}
