//
//  MovieDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

// MARK: - MovieDetailHeroHeaderView

@MainActor
final class MovieDetailHeroHeaderView: DetailHeroHeaderView {

    static let reuseIdentifier = String(describing: MovieDetailHeroHeaderView.self)

    func configure(with item: MovieDetailHeroItem) {
        configure(
            with: DetailHeroHeaderContent(
                title: item.title,
                originalTitle: item.originalTitle,
                tagline: item.tagline,
                posterURL: item.posterURL,
                backdropURL: item.backdropURL,
                scoreText: item.scoreText,
                voteCountText: item.voteCountText,
                metadataText: item.metadataText
            )
        )
    }
}
