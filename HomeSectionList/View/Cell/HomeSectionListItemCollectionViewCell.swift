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

    func configure(
        with item: MainHomeContentItem,
        imageHeight: CGFloat
    ) {
        configure(with: ImageTitleCellContent(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: "評分 \(item.scoreText)",
            imageHeight: imageHeight
        ))
    }
}
