//
//  MainTVListSeriesCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListSeriesCollectionViewCell

@MainActor
final class MainTVListSeriesCollectionViewCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainTVListSeriesCollectionViewCell.self)

    func configure(
        with item: TVGridSeriesItem,
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
