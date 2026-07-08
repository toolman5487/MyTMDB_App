//
//  MainHomeSectionCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import UIKit

// MARK: - MainHomeTrendingMoviesSectionCollectionViewCell

@MainActor
final class MainHomeTrendingMoviesSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeTrendingMoviesSectionCollectionViewCell.self)
}

// MARK: - MainHomeTrendingTVSectionCollectionViewCell

@MainActor
final class MainHomeTrendingTVSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeTrendingTVSectionCollectionViewCell.self)
}

// MARK: - MainHomePopularMoviesSectionCollectionViewCell

@MainActor
final class MainHomePopularMoviesSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomePopularMoviesSectionCollectionViewCell.self)
}

// MARK: - MainHomePopularTVSectionCollectionViewCell

@MainActor
final class MainHomePopularTVSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomePopularTVSectionCollectionViewCell.self)
}

// MARK: - MainHomeOnTheAirTVSectionCollectionViewCell

@MainActor
final class MainHomeOnTheAirTVSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeOnTheAirTVSectionCollectionViewCell.self)
}

// MARK: - MainHomeUpcomingMoviesSectionCollectionViewCell

@MainActor
final class MainHomeUpcomingMoviesSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeUpcomingMoviesSectionCollectionViewCell.self)
}

// MARK: - MainHomeAiringTodayTVSectionCollectionViewCell

@MainActor
final class MainHomeAiringTodayTVSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeAiringTodayTVSectionCollectionViewCell.self)
}

// MARK: - MainHomeTopRatedMoviesSectionCollectionViewCell

@MainActor
final class MainHomeTopRatedMoviesSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeTopRatedMoviesSectionCollectionViewCell.self)
}

// MARK: - MainHomeTopRatedTVSectionCollectionViewCell

@MainActor
final class MainHomeTopRatedTVSectionCollectionViewCell: MainHomeContentStripCollectionViewCell {
    static let reuseIdentifier = String(describing: MainHomeTopRatedTVSectionCollectionViewCell.self)
}

// MARK: - MainHomeContentCategory + Section Cell

extension MainHomeContentCategory {

    @MainActor
    var sectionCellReuseIdentifier: String {
        switch self {
        case .trendingMovies:
            return MainHomeTrendingMoviesSectionCollectionViewCell.reuseIdentifier

        case .trendingTV:
            return MainHomeTrendingTVSectionCollectionViewCell.reuseIdentifier

        case .popularMovies:
            return MainHomePopularMoviesSectionCollectionViewCell.reuseIdentifier

        case .popularTV:
            return MainHomePopularTVSectionCollectionViewCell.reuseIdentifier

        case .nowPlayingMovies:
            assertionFailure("nowPlayingMovies is rendered in the featured carousel header")
            return MainHomeTrendingMoviesSectionCollectionViewCell.reuseIdentifier

        case .onTheAirTV:
            return MainHomeOnTheAirTVSectionCollectionViewCell.reuseIdentifier

        case .upcomingMovies:
            return MainHomeUpcomingMoviesSectionCollectionViewCell.reuseIdentifier

        case .airingTodayTV:
            return MainHomeAiringTodayTVSectionCollectionViewCell.reuseIdentifier

        case .topRatedMovies:
            return MainHomeTopRatedMoviesSectionCollectionViewCell.reuseIdentifier

        case .topRatedTV:
            return MainHomeTopRatedTVSectionCollectionViewCell.reuseIdentifier
        }
    }
}
