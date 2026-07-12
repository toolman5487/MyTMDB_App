//
//  MainMemberCenterSectionCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MainMemberCenterFavoriteMoviesSectionCollectionViewCell

@MainActor
final class MainMemberCenterFavoriteMoviesSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterFavoriteMoviesSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterFavoriteTVSectionCollectionViewCell

@MainActor
final class MainMemberCenterFavoriteTVSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterFavoriteTVSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterWatchlistMoviesSectionCollectionViewCell

@MainActor
final class MainMemberCenterWatchlistMoviesSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterWatchlistMoviesSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterWatchlistTVSectionCollectionViewCell

@MainActor
final class MainMemberCenterWatchlistTVSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterWatchlistTVSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterRatedMoviesSectionCollectionViewCell

@MainActor
final class MainMemberCenterRatedMoviesSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterRatedMoviesSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterRatedTVSectionCollectionViewCell

@MainActor
final class MainMemberCenterRatedTVSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterRatedTVSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterRatedEpisodesSectionCollectionViewCell

@MainActor
final class MainMemberCenterRatedEpisodesSectionCollectionViewCell: MainMemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterRatedEpisodesSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterListsSectionCollectionViewCell

@MainActor
final class MainMemberCenterListsSectionCollectionViewCell: MainMemberCenterListStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberCenterListsSectionCollectionViewCell.self)
}

// MARK: - MainMemberCenterDestination + Section Cell

extension MainMemberCenterDestination {

    @MainActor
    var sectionCellReuseIdentifier: String {
        switch self {
        case .favoriteMovies:
            return MainMemberCenterFavoriteMoviesSectionCollectionViewCell.reuseIdentifier

        case .favoriteTV:
            return MainMemberCenterFavoriteTVSectionCollectionViewCell.reuseIdentifier

        case .watchlistMovies:
            return MainMemberCenterWatchlistMoviesSectionCollectionViewCell.reuseIdentifier

        case .watchlistTV:
            return MainMemberCenterWatchlistTVSectionCollectionViewCell.reuseIdentifier

        case .ratedMovies:
            return MainMemberCenterRatedMoviesSectionCollectionViewCell.reuseIdentifier

        case .ratedTV:
            return MainMemberCenterRatedTVSectionCollectionViewCell.reuseIdentifier

        case .ratedEpisodes:
            return MainMemberCenterRatedEpisodesSectionCollectionViewCell.reuseIdentifier

        case .lists:
            return MainMemberCenterListsSectionCollectionViewCell.reuseIdentifier
        }
    }
}
