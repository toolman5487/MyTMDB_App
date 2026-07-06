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

    private enum Layout {
        static let imageCornerRadius: CGFloat = 8
    }

    func configure(
        with item: TVGridSeriesItem,
        imageHeight: CGFloat
    ) {
        configureLayout(
            imageHeight: imageHeight,
            imageCornerRadius: Layout.imageCornerRadius
        )
        configure(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: "評分 \(item.scoreText)"
        )
    }
}
