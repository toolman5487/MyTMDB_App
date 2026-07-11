//
//  BaseHorizontalStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/11.
//

import SnapKit
import UIKit

// MARK: - BaseHorizontalStripCollectionViewCell

@MainActor
class BaseHorizontalStripCollectionViewCell<Item, ItemCell: UICollectionViewCell>: BaseNestedCollectionViewCell,
    UICollectionViewDataSource,
    UICollectionViewDelegate
{

    private var items: [Item] = []
    private var onItemSelected: ((Item) -> Void)?
    private var configureItemCell: ((ItemCell, Item) -> Void)?
    private var itemCellReuseIdentifier: String?

    override func configureView() {
        super.configureView()
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
        collectionView.dataSource = self
        collectionView.delegate = self
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
        configureItemCell = nil
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    func configureHorizontalStrip(
        cellType: ItemCell.Type,
        reuseIdentifier: String,
        itemSize: CGSize
    ) {
        itemCellReuseIdentifier = reuseIdentifier
        collectionViewFlowLayout.itemSize = itemSize
        collectionView.register(
            cellType,
            forCellWithReuseIdentifier: reuseIdentifier
        )
    }

    func updateItemSize(_ itemSize: CGSize) {
        collectionViewFlowLayout.itemSize = itemSize
        collectionViewFlowLayout.invalidateLayout()
    }

    func configureItems(
        _ items: [Item],
        onItemSelected: ((Item) -> Void)? = nil,
        configureItemCell: @escaping (ItemCell, Item) -> Void
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        self.configureItemCell = configureItemCell
        collectionView.reloadData()
    }

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
        guard let itemCellReuseIdentifier else {
            return UICollectionViewCell()
        }

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: itemCellReuseIdentifier,
            for: indexPath
        )

        if let itemCell = cell as? ItemCell {
            configureItemCell?(itemCell, items[indexPath.item])
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)

        guard items.indices.contains(indexPath.item) else { return }
        onItemSelected?(items[indexPath.item])
    }
}
