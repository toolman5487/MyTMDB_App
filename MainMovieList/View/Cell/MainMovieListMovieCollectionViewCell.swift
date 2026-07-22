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

    func configure(
        with item: MovieGridMovieItem,
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
