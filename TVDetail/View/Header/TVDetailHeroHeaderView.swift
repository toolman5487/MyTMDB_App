//
//  TVDetailHeroHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

// MARK: - TVDetailHeroHeaderView

@MainActor
final class TVDetailHeroHeaderView: DetailHeroHeaderView {

    static let reuseIdentifier = String(describing: TVDetailHeroHeaderView.self)

    func configure(with item: TVDetailHeroItem) {
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
