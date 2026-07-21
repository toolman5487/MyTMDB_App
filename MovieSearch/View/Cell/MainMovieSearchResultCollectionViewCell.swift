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

    func configure(
        with item: MovieGridMovieItem,
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
