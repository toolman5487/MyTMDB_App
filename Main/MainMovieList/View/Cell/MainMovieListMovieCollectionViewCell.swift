//
//  MainMovieListMovieCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieListMovieCollectionViewCell

@MainActor
final class MainMovieListMovieCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMovieListMovieCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
            imageHeight: imageHeight,
            accessibilityText: item.mainMovieListAccessibilityText
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    var mainMovieListAccessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                BaseDisplayTextFormatter.ratingText(scoreText),
                "上映日期 \(dateText)"
            ]),
            hint: "點兩下開啟電影詳細資料"
        )
    }
}
