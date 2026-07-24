//
//  MainSearchTrendingCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import UIKit

// MARK: - MainSearchTrendingCollectionViewCell

@MainActor
final class MainSearchTrendingCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchTrendingCollectionViewCell.self)

    func configure(
        with item: MainSearchResultItem,
        imageHeight: CGFloat
    ) {
        configure(
            with: ImageTitleCellContent(
                imageURL: item.imageURL,
                title: item.title,
                subtitle: item.subtitle,
                imageHeight: imageHeight
            )
        )
    }
}
