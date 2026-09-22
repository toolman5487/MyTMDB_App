//
//  MediaGridLayoutMetrics.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MediaGridLayoutMetrics

nonisolated enum MediaGridLayoutMetrics {
    static let horizontalInset: CGFloat = 16
    static let itemSpacing: CGFloat = 12

    private static let columnCount: CGFloat = 3
    private static let posterAspectRatio: CGFloat = 1.5
    private static let minimumTextHeight: CGFloat = 40
    private static let textVerticalSpacing: CGFloat = 4

    private static var textHeight: CGFloat {
        let titleHeight = ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
        let metadataHeight = ceil(UIFont.preferredFont(forTextStyle: .caption2).lineHeight)
        return max(
            minimumTextHeight,
            titleHeight + textVerticalSpacing + metadataHeight
        )
    }

    static func itemWidth(for collectionViewWidth: CGFloat) -> CGFloat {
        let totalHorizontalInsets = horizontalInset * 2
        let totalItemSpacing = itemSpacing * (columnCount - 1)
        let availableWidth = collectionViewWidth - totalHorizontalInsets - totalItemSpacing

        return floor(max(availableWidth, 0) / columnCount)
    }

    static func posterHeight(for collectionViewWidth: CGFloat) -> CGFloat {
        itemWidth(for: collectionViewWidth) * posterAspectRatio
    }

    static func itemSize(for collectionViewWidth: CGFloat) -> CGSize {
        let itemWidth = itemWidth(for: collectionViewWidth)

        return CGSize(
            width: itemWidth,
            height: posterHeight(for: collectionViewWidth) + textHeight
        )
    }
}
