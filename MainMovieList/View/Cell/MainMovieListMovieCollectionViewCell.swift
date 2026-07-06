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
