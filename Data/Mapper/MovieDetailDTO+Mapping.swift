//
//  MovieDetailDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
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

// MARK: - GenreDTO Mapping

extension GenreDTO {

    func mapped() -> Genre {
        Genre(id: id, name: name)
    }
}

// MARK: - ProductionCompanyDTO Mapping

extension ProductionCompanyDTO {

    func mapped() -> ProductionCompany {
        ProductionCompany(
            id: id,
            name: name,
            logoPath: logoPath,
            originCountry: originCountry
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

// MARK: - MovieVideosDTO Mapping

extension MovieVideosDTO {

    func mapped() -> [Video] {
        results.map { $0.mapped() }
    }
}

// MARK: - VideoDTO Mapping

extension VideoDTO {

    func mapped() -> Video {
        Video(
            id: id,
            name: name,
            key: key,
            site: site,
            type: type,
            isOfficial: official
        )
    }
}

// MARK: - MediaImagesDTO Mapping

extension MediaImagesDTO {

    func mapped() -> MediaImages {
        MediaImages(
            backdrops: backdrops.map { $0.mapped() },
            posters: posters.map { $0.mapped() },
            logos: logos.map { $0.mapped() }
        )
    }
}

// MARK: - MediaImageDTO Mapping

extension MediaImageDTO {

    func mapped() -> MediaImage {
        MediaImage(filePath: filePath, width: width, height: height)
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

// MARK: - MovieSummaryPageDTO Mapping

extension MovieSummaryPageDTO {

    func mapped() -> Page<MovieSummary> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map { $0.mapped() }
        )
    }
}

// MARK: - MovieSummaryDTO Mapping

extension MovieSummaryDTO {

    func mapped() -> MovieSummary {
        MovieSummary(
            id: id,
            title: title,
            posterPath: posterPath,
            releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
}

// MARK: - WatchProvidersDTO Mapping

extension WatchProvidersDTO {

    func mapped() -> WatchProviders {
        WatchProviders(countries: results.mapValues { $0.mapped() })
    }
}

// MARK: - WatchProviderCountryDTO Mapping

extension WatchProviderCountryDTO {

    func mapped() -> WatchProviderCountry {
        WatchProviderCountry(
            link: link,
            flatrate: flatrate.map { $0.mapped() },
            rent: rent.map { $0.mapped() },
            buy: buy.map { $0.mapped() },
            free: free.map { $0.mapped() },
            ads: ads.map { $0.mapped() }
        )
    }
}

// MARK: - WatchProviderDTO Mapping

extension WatchProviderDTO {

    func mapped() -> WatchProvider {
        WatchProvider(
            id: id,
            name: name,
            logoPath: logoPath,
            displayPriority: displayPriority
        )
    }
}
