//
//  MemberCenterSectionCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MemberCenterFavoriteMoviesSectionCollectionViewCell

@MainActor
final class MemberCenterFavoriteMoviesSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterFavoriteMoviesSectionCollectionViewCell.self)
}

// MARK: - MemberCenterFavoriteTVSectionCollectionViewCell

@MainActor
final class MemberCenterFavoriteTVSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterFavoriteTVSectionCollectionViewCell.self)
}

// MARK: - MemberCenterWatchlistMoviesSectionCollectionViewCell

@MainActor
final class MemberCenterWatchlistMoviesSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterWatchlistMoviesSectionCollectionViewCell.self)
}

// MARK: - MemberCenterWatchlistTVSectionCollectionViewCell

@MainActor
final class MemberCenterWatchlistTVSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterWatchlistTVSectionCollectionViewCell.self)
}

// MARK: - MemberCenterRatedMoviesSectionCollectionViewCell

@MainActor
final class MemberCenterRatedMoviesSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterRatedMoviesSectionCollectionViewCell.self)
}

// MARK: - MemberCenterRatedTVSectionCollectionViewCell

@MainActor
final class MemberCenterRatedTVSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterRatedTVSectionCollectionViewCell.self)
}

// MARK: - MemberCenterRatedEpisodesSectionCollectionViewCell

@MainActor
final class MemberCenterRatedEpisodesSectionCollectionViewCell: MemberCenterContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterRatedEpisodesSectionCollectionViewCell.self)
}

// MARK: - MemberCenterListsSectionCollectionViewCell

@MainActor
final class MemberCenterListsSectionCollectionViewCell: MemberCenterListStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MemberCenterListsSectionCollectionViewCell.self)
}

// MARK: - MemberCenterDestination + Section Cell

extension MemberCenterDestination {

    @MainActor
    var sectionCellReuseIdentifier: String {
        switch self {
        case .favoriteMovies:
            return MemberCenterFavoriteMoviesSectionCollectionViewCell.reuseIdentifier

        case .favoriteTV:
            return MemberCenterFavoriteTVSectionCollectionViewCell.reuseIdentifier

        case .watchlistMovies:
            return MemberCenterWatchlistMoviesSectionCollectionViewCell.reuseIdentifier

        case .watchlistTV:
            return MemberCenterWatchlistTVSectionCollectionViewCell.reuseIdentifier

        case .ratedMovies:
            return MemberCenterRatedMoviesSectionCollectionViewCell.reuseIdentifier

        case .ratedTV:
            return MemberCenterRatedTVSectionCollectionViewCell.reuseIdentifier

        case .ratedEpisodes:
            return MemberCenterRatedEpisodesSectionCollectionViewCell.reuseIdentifier

        case .lists:
            return MemberCenterListsSectionCollectionViewCell.reuseIdentifier
        }
    }
}
