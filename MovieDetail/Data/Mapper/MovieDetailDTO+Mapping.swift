//
//  MovieDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - MovieDetailDTO Mapping

extension MovieDetailDTO {

    func mapped() -> Movie {
        Movie(
            id: id,
            title: title,
            originalTitle: originalTitle,
            tagline: tagline,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            genres: genres.map { $0.mapped() },
            productionCompanies: productionCompanies.map { $0.mapped() },
            releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
            runtime: runtime.flatMap { $0 > 0 ? .seconds($0 * 60) : nil },
            budget: budget,
            revenue: revenue,
            voteAverage: voteAverage,
            voteCount: voteCount,
            status: MovieStatus(rawText: status),
            homepage: homepage.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            imdbID: imdbID.flatMap { $0.isEmpty ? nil : $0 },
            collectionID: belongsToCollection?.id
        )
    }
}

// MARK: - MovieCreditsDTO Mapping

extension MovieCreditsDTO {

    func mapped() -> MovieCredits {
        MovieCredits(
            cast: cast.map { $0.mapped() },
            crew: crew.map { $0.mapped() }
        )
    }
}

// MARK: - CastMemberDTO Mapping

extension CastMemberDTO {

    func mapped() -> CastMember {
        CastMember(
            id: id,
            name: name,
            character: character,
            profilePath: profilePath,
            order: order
        )
    }
}

// MARK: - CrewMemberDTO Mapping

extension CrewMemberDTO {

    func mapped() -> CrewMember {
        CrewMember(
            id: id,
            creditID: creditID,
            name: name,
            job: job,
            department: department,
            profilePath: profilePath
        )
    }
}

// MARK: - MovieCollectionDTO Mapping

extension MovieCollectionDTO {

    func mapped() -> MovieCollection {
        MovieCollection(
            id: id,
            name: name,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            parts: parts.map { $0.mapped() }
        )
    }
}

// MARK: - MovieCollectionPartDTO Mapping

extension MovieCollectionPartDTO {

    func mapped() -> MovieCollectionPart {
        MovieCollectionPart(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
}
