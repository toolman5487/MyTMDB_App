//
//  MainMediaListItemCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMediaListItemCollectionViewCell

@MainActor
final class MainMediaListItemCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMediaListItemCollectionViewCell.self)

    func configure(
        with item: MediaGridItem,
        imageHeight: CGFloat,
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: item.ratingText(localization: localization),
            imageHeight: imageHeight,
            accessibilityText: item.mainMediaListAccessibilityText(
                mediaKind: mediaKind,
                localization: localization
            )
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    func mainMediaListAccessibilityText(
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                ratingText(localization: localization),
                localization.formatted(
                    "common.release_date.value_format",
                    defaultValue: "Release date %@",
                    dateText
                )
            ]),
            hint: mediaKind.detailAccessibilityHint(localization: localization)
        )
    }
}
