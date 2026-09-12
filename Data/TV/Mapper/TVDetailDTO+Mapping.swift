//
//  TVDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - TVSeriesDTO Mapping

extension TVSeriesDTO {

    func mapped() -> TVSeries {
        TVSeries(
            id: id,
            name: name,
            originalName: originalName,
            tagline: tagline,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            creators: createdBy.map { $0.mapped() },
            episodeRunTimes: episodeRunTime.compactMap { $0 > 0 ? .seconds($0 * 60) : nil },
            firstAirDate: CalendarDayParsing.calendarDay(from: firstAirDate),
            lastAirDate: CalendarDayParsing.calendarDay(from: lastAirDate),
            genres: genres.map { $0.mapped() },
            networks: networks.map { $0.mapped() },
            productionCompanies: productionCompanies.map { $0.mapped() },
            seasons: seasons.map { $0.mapped() },
            lastEpisodeToAir: lastEpisodeToAir?.mapped(),
            nextEpisodeToAir: nextEpisodeToAir?.mapped(),
            numberOfSeasons: numberOfSeasons,
            numberOfEpisodes: numberOfEpisodes,
            isInProduction: inProduction,
            status: TVStatus(rawText: status),
            type: type,
            voteAverage: voteAverage,
            voteCount: voteCount,
            homepage: homepage.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        )
    }
}

// MARK: - CreatorDTO Mapping

extension CreatorDTO {

    func mapped() -> Creator {
        Creator(id: id, creditID: creditID, name: name, profilePath: profilePath)
    }
}

// MARK: - NetworkDTO Mapping

extension NetworkDTO {

    func mapped() -> Network {
        Network(id: id, name: name, logoPath: logoPath, originCountry: originCountry)
    }
}

// MARK: - TVSeasonDTO Mapping

extension TVSeasonDTO {

    func mapped() -> TVSeason {
        TVSeason(
            id: id,
            name: name,
            overview: overview,
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            episodeCount: episodeCount,
            posterPath: posterPath,
            seasonNumber: seasonNumber,
            voteAverage: voteAverage
        )
    }
}

// MARK: - TVEpisodeDTO Mapping

extension TVEpisodeDTO {

    func mapped() -> TVEpisode {
        TVEpisode(
            id: id,
            name: name,
            overview: overview,
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            episodeNumber: episodeNumber,
            seasonNumber: seasonNumber,
            stillPath: stillPath,
            voteAverage: voteAverage
        )
    }
}

// MARK: - AggregateCreditsDTO Mapping

extension AggregateCreditsDTO {

    func mapped() -> AggregateCredits {
        AggregateCredits(
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() }
        )
    }
}

// MARK: - AggregateCastMemberDTO Mapping

extension AggregateCastMemberDTO {

    func mapped() -> AggregateCastMember {
        AggregateCastMember(
            id: id,
            name: name,
            characters: roles
                .map(\.character)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            episodeCount: totalEpisodeCount,
            profilePath: profilePath,
            order: order
        )
    }
}

// MARK: - AggregateCrewMemberDTO Mapping

extension AggregateCrewMemberDTO {

    func mapped() -> AggregateCrewMember {
        AggregateCrewMember(
            id: id,
            name: name,
            department: department,
            jobs: jobs
                .map(\.job)
                .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
            episodeCount: totalEpisodeCount,
            profilePath: profilePath
        )
    }
}
