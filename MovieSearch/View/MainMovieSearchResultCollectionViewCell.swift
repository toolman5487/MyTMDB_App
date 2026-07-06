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

    private enum Layout {
        static let imageCornerRadius: CGFloat = 8
    }

    func configure(
        with item: MovieGridMovieItem,
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
