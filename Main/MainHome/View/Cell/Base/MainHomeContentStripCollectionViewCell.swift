//
//  MainHomeContentStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import UIKit

// MARK: - MainHomeContentStripCollectionViewCell

@MainActor
class MainHomeContentStripCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    MainHomeContentItem,
    MainHomePosterCollectionViewCell
> {

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: MainHomePosterCollectionViewCell.self,
            reuseIdentifier: MainHomePosterCollectionViewCell.reuseIdentifier,
            itemSize: CGSize(
                width: Layout.posterWidth,
                height: Layout.itemHeight
            )
        )
    }

    func configure(
        contents: [MainHomeContentItem],
        onContentSelected: @escaping (MainHomeContentItem) -> Void
    ) {
        configureItems(
            contents,
            onItemSelected: onContentSelected
        ) { cell, item in
            cell.configure(with: item)
        }
    }
}
