//
//  MovieGridLayoutMetrics.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MovieGridLayoutMetrics

nonisolated enum MovieGridLayoutMetrics {
    static let horizontalInset: CGFloat = 16
    static let itemSpacing: CGFloat = 12
    static let textHeight: CGFloat = 40
    static let paginationThreshold = 4

    private static let columnCount: CGFloat = 3
    private static let posterAspectRatio: CGFloat = 1.5

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

    static func shouldLoadNextPage(currentIndex: Int, itemCount: Int) -> Bool {
        let thresholdIndex = max(itemCount - paginationThreshold, 0)
        return currentIndex >= thresholdIndex
    }
}
