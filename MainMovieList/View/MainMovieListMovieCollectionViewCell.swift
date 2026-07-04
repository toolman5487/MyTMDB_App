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

    // MARK: - Layout

    private enum Layout {
        static let imageCornerRadius: CGFloat = 8
    }

    // MARK: - Configuration

    func configure(
        with item: MainMovieListMovieItem,
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
