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
            imageHeight: imageHeight
        ))
    }
}
