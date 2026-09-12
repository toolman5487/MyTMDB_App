//
//  SearchResultCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - SearchResultCollectionViewCell

@MainActor
final class SearchResultCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: SearchResultCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        kind: MediaKind,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
            imageHeight: imageHeight,
            accessibilityText: item.searchAccessibilityText(kind: kind)
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    func searchAccessibilityText(kind: MediaKind) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                kind.displayName,
                BaseDisplayTextFormatter.ratingText(scoreText),
                "上映日期 \(dateText)"
            ]),
            hint: "點兩下開啟\(kind.displayName)詳細資料"
        )
    }
}
