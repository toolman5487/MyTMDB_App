//
//  AccountContentDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - RatedMediaDTO Mapping

extension RatedMediaDTO {

    func mapped(kind: MediaKind) -> RatedMedia {
        RatedMedia(
            summary: MediaSummary(
                id: id,
                title: title,
                overview: overview,
                posterPath: posterPath,
                backdropPath: backdropPath,
                releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
                voteAverage: voteAverage,
                voteCount: voteCount,
                popularity: popularity,
                genreIDs: []
            ),
            kind: kind,
            rating: rating
        )
    }
}

// MARK: - RatedEpisodeDTO Mapping

extension RatedEpisodeDTO {

    func mapped() -> RatedEpisode {
        RatedEpisode(
            id: id,
            seriesID: showID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: name,
            overview: overview,
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            stillPath: stillPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            rating: rating
        )
    }
}

// MARK: - AccountListDTO Mapping

extension AccountListDTO {

    func mapped() -> AccountList {
        AccountList(
            id: id,
            name: name,
            description: description,
            languageCode: languageCode,
            listType: listType,
            itemCount: itemCount,
            favoriteCount: favoriteCount,
            posterPath: posterPath
        )
    }
}
