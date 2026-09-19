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
        imageHeight: CGFloat,
        localization: AppInterfaceLocalization
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: item.ratingText(localization: localization),
            imageHeight: imageHeight,
            accessibilityText: item.searchAccessibilityText(
                kind: kind,
                localization: localization
            )
        ))
    }
}

// MARK: - Accessibility

private extension MediaGridItem {

    func searchAccessibilityText(
        kind: MediaKind,
        localization: AppInterfaceLocalization
    ) -> AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                kind.displayName(localization: localization),
                ratingText(localization: localization),
                localization.formatted(
                    "common.release_date.value_format",
                    defaultValue: "Release date %@",
                    dateText
                )
            ]),
            hint: kind.detailAccessibilityHint(localization: localization)
        )
    }
}
