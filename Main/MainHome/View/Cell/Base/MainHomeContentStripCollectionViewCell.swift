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
        static let posterHeight: CGFloat = 186
        static let titleTopSpacing: CGFloat = 4
        private static let minimumItemHeight: CGFloat = 232

        static var itemHeight: CGFloat {
            let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            let scoreHeight = ceil(UIFont.preferredFont(forTextStyle: .caption2).lineHeight)
            return max(
                minimumItemHeight,
                posterHeight + titleTopSpacing + titleHeight + scoreHeight
            )
        }
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
        updateItemSize(
            CGSize(
                width: Layout.posterWidth,
                height: Layout.itemHeight
            )
        )
        configureItems(
            contents,
            onItemSelected: onContentSelected
        ) { cell, item in
            cell.configure(with: item)
        }
    }
}
