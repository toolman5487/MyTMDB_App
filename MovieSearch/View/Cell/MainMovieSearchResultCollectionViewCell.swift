//
//  MainMovieSearchResultCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainMovieSearchResultCollectionViewCell

@MainActor
final class MainMovieSearchResultCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMovieSearchResultCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
            imageHeight: imageHeight,
            accessibilityText: item.movieSearchAccessibilityText
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    var movieSearchAccessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                "電影",
                BaseDisplayTextFormatter.ratingText(scoreText),
                "上映日期 \(dateText)"
            ]),
            hint: "點兩下開啟電影詳細資料"
        )
    }
}
