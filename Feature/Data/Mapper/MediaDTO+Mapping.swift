//
//  MediaDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

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

// MARK: - VideosDTO Mapping

extension VideosDTO {

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
        MediaImage(
            filePath: filePath,
            aspectRatio: aspectRatio,
            width: width,
            height: height
        )
    }
}

// MARK: - MediaSummaryPageDTO Mapping

extension MediaSummaryPageDTO {

    func mapped() -> Page<MediaSummary> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map { $0.mapped() }
        )
    }
}

// MARK: - MediaSummaryDTO Mapping

extension MediaSummaryDTO {

    func mapped() -> MediaSummary {
        MediaSummary(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: CalendarDayParsing.calendarDay(from: releaseDate),
            voteAverage: voteAverage,
            voteCount: voteCount,
            popularity: popularity
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
