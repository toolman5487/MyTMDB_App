//
//  MainMemberCenterContentStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MainMemberCenterContentStripCollectionViewCell

@MainActor
class MainMemberCenterContentStripCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainMemberCenterListItem,
    MainMemberCenterListItemCollectionViewCell
> {

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainMemberCenterListItemCollectionViewCell.self,
            reuseIdentifier: MainMemberCenterListItemCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(
                width: Layout.posterWidth,
                height: Layout.itemHeight
            )
        )
    }

    func configure(
        items: [MainMemberCenterListItem],
        onItemSelected: @escaping (MainMemberCenterListItem) -> Void
    ) {
        configureItems(
            items,
            onItemSelected: onItemSelected
        ) { cell, item in
            cell.configure(with: item)
        }
    }
}
