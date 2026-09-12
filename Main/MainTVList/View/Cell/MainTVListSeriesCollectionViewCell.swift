//
//  MainTVListSeriesCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListSeriesCollectionViewCell

@MainActor
final class MainTVListSeriesCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainTVListSeriesCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
            imageHeight: imageHeight,
            accessibilityText: item.mainTVListAccessibilityText
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    var mainTVListAccessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                BaseDisplayTextFormatter.ratingText(scoreText),
                "上映日期 \(dateText)"
            ]),
            hint: "點兩下開啟影集詳細資料"
        )
    }
}
