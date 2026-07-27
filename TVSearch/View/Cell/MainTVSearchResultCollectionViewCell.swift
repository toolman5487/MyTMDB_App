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
        with item: TVGridSeriesItem,
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

private extension TVGridSeriesItem {

    var tvSearchAccessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                "劇集",
                BaseDisplayTextFormatter.ratingText(scoreText),
                "首播日期 \(firstAirDateText)"
            ]),
            hint: "點兩下開啟劇集詳細資料"
        )
    }
}
