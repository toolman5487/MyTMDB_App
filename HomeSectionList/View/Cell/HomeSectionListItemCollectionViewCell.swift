//
//  HomeSectionListItemCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import UIKit

// MARK: - HomeSectionListItemCollectionViewCell

@MainActor
final class HomeSectionListItemCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: HomeSectionListItemCollectionViewCell.self)

    private enum Layout {
        static let imageCornerRadius: CGFloat = 8
    }

    func configure(
        with item: MainHomeContentItem,
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
