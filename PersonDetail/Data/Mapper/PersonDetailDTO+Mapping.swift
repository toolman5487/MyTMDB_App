//
//  PersonDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - Person Detail Mapping

extension PersonDetailDTO {

    func mapped() -> Person {
        Person(
            id: id,
            adult: adult,
            alsoKnownAs: alsoKnownAs,
            biography: biography,
            birthday: CalendarDayParsing.calendarDay(from: birthday),
            deathday: CalendarDayParsing.calendarDay(from: deathday),
            gender: PersonGender(rawValue: gender),
            homepage: homepage.flatMap(URL.init(string:)),
            imdbID: imdbID,
            knownForDepartment: knownForDepartment,
            name: name ?? "",
            placeOfBirth: placeOfBirth,
            popularity: popularity,
            profilePath: profilePath
        )
    }
}

// MARK: - Person Credits Mapping

extension PersonCreditsDTO {

    func mapped() -> PersonCredits {
        PersonCredits(
            id: id,
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() }
        )
    }
}

extension PersonCreditCastDTO {

    func mapped() -> PersonCreditCast {
        PersonCreditCast(
            id: id,
            adult: adult ?? false,
            backdropPath: backdropPath,
            character: character ?? "",
            creditID: creditID ?? "",
            episodeCount: episodeCount,
            genreIDs: genreIDs ?? [],
            mediaType: PersonCreditMediaType(rawValue: mediaType),
            originalLanguage: originalLanguage ?? "",
            originalTitle: originalTitle ?? originalName ?? "",
            overview: overview ?? "",
            popularity: popularity ?? 0,
            posterPath: posterPath,
            primaryDate: CalendarDayParsing.calendarDay(from: releaseDate ?? firstAirDate),
            title: title ?? name ?? "",
            video: video ?? false,
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}

extension PersonCreditCrewDTO {

    func mapped() -> PersonCreditCrew {
        PersonCreditCrew(
            id: id,
            adult: adult ?? false,
            backdropPath: backdropPath,
            creditID: creditID ?? "",
            department: department ?? "",
            episodeCount: episodeCount,
            genreIDs: genreIDs ?? [],
            job: job ?? "",
            mediaType: PersonCreditMediaType(rawValue: mediaType),
            originalLanguage: originalLanguage ?? "",
            originalTitle: originalTitle ?? originalName ?? "",
            overview: overview ?? "",
            popularity: popularity ?? 0,
            posterPath: posterPath,
            primaryDate: CalendarDayParsing.calendarDay(from: releaseDate ?? firstAirDate),
            title: title ?? name ?? "",
            video: video ?? false,
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0
        )
    }
}

// MARK: - Person Metadata Mapping

extension PersonImagesDTO {

    func mapped() -> PersonImages {
        PersonImages(id: id, profiles: profiles.map { $0.mapped() })
    }
}

extension PersonProfileImageDTO {

    func mapped() -> PersonProfileImage {
        PersonProfileImage(
            aspectRatio: aspectRatio ?? 0,
            filePath: filePath ?? "",
            height: height ?? 0,
            languageCode: languageCode,
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            width: width ?? 0
        )
    }
}

extension PersonExternalIDsDTO {

    func mapped() -> PersonExternalIDs {
        PersonExternalIDs(
            id: id,
            facebookID: facebookID,
            freebaseID: freebaseID,
            freebaseMID: freebaseMID,
            imdbID: imdbID,
            instagramID: instagramID,
            tiktokID: tiktokID,
            twitterID: twitterID,
            wikidataID: wikidataID,
            youtubeID: youtubeID
        )
    }
}

// MARK: - Raw Value Mapping

private extension PersonGender {

    init(rawValue: Int) {
        switch rawValue {
        case 0:
            self = .notSpecified

        case 1:
            self = .female

        case 2:
            self = .male

        case 3:
            self = .nonBinary

        default:
            self = .unknown(rawValue)
        }
    }
}

private extension PersonCreditMediaType {

    init(rawValue: String?) {
        switch rawValue {
        case "movie":
            self = .movie

        case "tv":
            self = .tv

        case .some(let value):
            self = .unknown(value)

        case nil:
            self = .unknown("")
        }
    }
}
