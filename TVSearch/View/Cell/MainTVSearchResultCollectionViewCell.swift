//
//  MainTVSearchResultCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVSearchResultCollectionViewCell

@MainActor
final class MainTVSearchResultCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainTVSearchResultCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
            imageHeight: imageHeight,
            accessibilityText: item.tvSearchAccessibilityText
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    var tvSearchAccessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                "影集",
                BaseDisplayTextFormatter.ratingText(scoreText),
                "上映日期 \(dateText)"
            ]),
            hint: "點兩下開啟影集詳細資料"
        )
    }
}
