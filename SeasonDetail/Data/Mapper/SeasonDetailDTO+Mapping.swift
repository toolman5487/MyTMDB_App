//
//  SeasonDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonDetailDTO Mapping

extension SeasonDetailDTO {

    func mapped() -> Season {
        Season(
            id: id,
            tmdbInternalID: tmdbInternalID ?? "",
            name: name ?? "",
            overview: overview ?? "",
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            episodes: episodes.map { $0.mapped() },
            posterPath: posterPath,
            seasonNumber: seasonNumber,
            voteAverage: voteAverage
        )
    }
}

// MARK: - SeasonEpisodeDTO Mapping

extension SeasonEpisodeDTO {

    func mapped() -> SeasonEpisode {
        SeasonEpisode(
            id: id,
            name: name ?? "",
            overview: overview ?? "",
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            episodeNumber: episodeNumber,
            episodeType: episodeType ?? "",
            productionCode: productionCode ?? "",
            runtime: runtimeInMinutes.flatMap { $0 > 0 ? .seconds($0 * 60) : nil },
            seasonNumber: seasonNumber,
            showID: showID,
            stillPath: stillPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            crew: crew.map { $0.mapped() },
            guestStars: guestStars.map { $0.mapped() }
        )
    }
}

extension SeasonEpisodeCrewMemberDTO {

    func mapped() -> SeasonEpisodeCrewMember {
        let resolvedName = name ?? ""

        return SeasonEpisodeCrewMember(
            id: id,
            creditID: creditID ?? "\(id)-\(department ?? "")-\(job ?? "")",
            department: department ?? "",
            job: job ?? "",
            name: resolvedName,
            originalName: originalName ?? resolvedName,
            profilePath: profilePath
        )
    }
}

extension SeasonEpisodeGuestStarDTO {

    func mapped() -> SeasonEpisodeGuestStar {
        SeasonEpisodeGuestStar(
            id: id,
            character: character ?? "",
            creditID: creditID ?? "\(id)-\(order ?? 0)-\(character ?? "")",
            name: name ?? "",
            order: order ?? 0,
            profilePath: profilePath
        )
    }
}

// MARK: - SeasonCreditsDTO Mapping

extension SeasonCreditsDTO {

    func mapped() -> SeasonCredits {
        SeasonCredits(
            id: id,
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() },
            guestStars: guestStars.map { $0.mapped() }
        )
    }
}

extension SeasonCreditCastDTO {

    func mapped() -> SeasonCreditCast {
        SeasonCreditCast(
            id: id,
            character: character ?? "",
            creditID: creditID ?? "\(id)-\(order ?? 0)-\(character ?? "")",
            name: name ?? "",
            order: order ?? 0,
            profilePath: profilePath
        )
    }
}

extension SeasonCreditCrewDTO {

    func mapped() -> SeasonCreditCrew {
        SeasonCreditCrew(
            id: id,
            creditID: creditID ?? "\(id)-\(department ?? "")-\(job ?? "")",
            department: department ?? "",
            job: job ?? "",
            name: name ?? "",
            profilePath: profilePath
        )
    }
}

// MARK: - Season Metadata DTO Mapping

extension SeasonExternalIDsDTO {

    func mapped() -> SeasonExternalIDs {
        SeasonExternalIDs(
            id: id,
            freebaseMID: freebaseMID,
            freebaseID: freebaseID,
            tvdbID: tvdbID,
            tvrageID: tvrageID,
            wikidataID: wikidataID
        )
    }
}

extension SeasonTranslationsDTO {

    func mapped() -> SeasonTranslations {
        SeasonTranslations(id: id, items: translations.map { $0.mapped() })
    }
}

extension SeasonTranslationDTO {

    func mapped() -> SeasonTranslation {
        SeasonTranslation(
            countryCode: countryCode,
            languageCode: languageCode,
            name: name,
            englishName: englishName,
            content: data.mapped()
        )
    }
}

extension SeasonTranslationContentDTO {

    func mapped() -> SeasonTranslationContent {
        SeasonTranslationContent(
            name: name ?? "",
            overview: overview ?? "",
            homepage: homepage.flatMap(URL.init(string:))
        )
    }
}

extension SeasonAccountStateDTO {

    func mapped() -> SeasonAccountState {
        SeasonAccountState(id: id, rating: rated.mapped())
    }
}

extension SeasonRatedStateDTO {

    func mapped() -> SeasonRatingState {
        switch self {
        case .unrated:
            return .unrated

        case .rated(let value):
            return .rated(value)
        }
    }
}
