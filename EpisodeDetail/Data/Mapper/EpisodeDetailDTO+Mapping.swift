//
//  EpisodeDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailDTO Mapping

extension EpisodeDetailDTO {

    func mapped() -> Episode {
        Episode(
            id: id,
            name: name ?? "",
            overview: overview ?? "",
            airDate: CalendarDayParsing.calendarDay(from: airDate),
            crew: crew.map { $0.mapped() },
            episodeNumber: episodeNumber,
            guestStars: guestStars.map { $0.mapped() },
            productionCode: productionCode ?? "",
            runtime: runtimeInMinutes.flatMap { $0 > 0 ? .seconds($0 * 60) : nil },
            seasonNumber: seasonNumber,
            stillPath: stillPath,
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
}

// MARK: - Episode Credits DTO Mapping

extension EpisodeCreditsDTO {

    func mapped() -> EpisodeCredits {
        EpisodeCredits(
            id: id,
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() },
            guestStars: guestStars.map { $0.mapped() }
        )
    }
}

extension EpisodeCastMemberDTO {

    func mapped() -> EpisodeCastMember {
        EpisodeCastMember(
            id: id,
            character: character ?? "",
            creditID: creditID ?? "\(id)-\(order ?? 0)-\(character ?? "")",
            name: name ?? "",
            order: order ?? 0,
            profilePath: profilePath
        )
    }
}

extension EpisodeCrewMemberDTO {

    func mapped() -> EpisodeCrewMember {
        EpisodeCrewMember(
            id: id,
            creditID: creditID ?? "\(id)-\(department ?? "")-\(job ?? "")",
            department: department ?? "",
            job: job ?? "",
            name: name ?? "",
            profilePath: profilePath
        )
    }
}

// MARK: - Episode Metadata DTO Mapping

extension EpisodeImagesDTO {

    func mapped() -> EpisodeImages {
        EpisodeImages(id: id, stills: stills.map { $0.mapped() })
    }
}

extension EpisodeExternalIDsDTO {

    func mapped() -> EpisodeExternalIDs {
        EpisodeExternalIDs(
            id: id,
            imdbID: imdbID,
            freebaseMID: freebaseMID,
            freebaseID: freebaseID,
            tvdbID: tvdbID,
            tvrageID: tvrageID,
            wikidataID: wikidataID
        )
    }
}

extension EpisodeTranslationsDTO {

    func mapped() -> EpisodeTranslations {
        EpisodeTranslations(id: id, items: translations.map { $0.mapped() })
    }
}

extension EpisodeTranslationDTO {

    func mapped() -> EpisodeTranslation {
        EpisodeTranslation(
            countryCode: countryCode,
            languageCode: languageCode,
            name: name,
            englishName: englishName,
            content: data.mapped()
        )
    }
}

extension EpisodeTranslationContentDTO {

    func mapped() -> EpisodeTranslationContent {
        EpisodeTranslationContent(name: name ?? "", overview: overview ?? "")
    }
}

extension EpisodeAccountStateDTO {

    func mapped() -> EpisodeAccountState {
        EpisodeAccountState(id: id, rating: rated.mapped())
    }
}

extension EpisodeRatedStateDTO {

    func mapped() -> EpisodeRatingState {
        switch self {
        case .unrated:
            return .unrated

        case .rated(let value):
            return .rated(value)
        }
    }
}
