//
//  MainSearchDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - MainSearchResultDTO Mapping

extension MainSearchResultDTO {

    func mapped() -> MainSearchResult? {
        guard let mediaType = mediaType.flatMap(MainSearchMediaType.init(rawValue:)) else {
            return nil
        }

        return MainSearchResult(
            id: id,
            mediaType: mediaType,
            title: title ?? name ?? "",
            overview: overview ?? "",
            posterPath: posterPath,
            profilePath: profilePath,
            primaryDate: CalendarDayParsing.calendarDay(from: releaseDate ?? firstAirDate),
            voteAverage: voteAverage ?? 0,
            voteCount: voteCount ?? 0,
            popularity: popularity ?? 0,
            knownForDepartment: knownForDepartment
        )
    }
}

// MARK: - MainSearchPopularPersonDTO Mapping

extension MainSearchPopularPersonDTO {

    func mapped() -> MainSearchPopularPerson {
        MainSearchPopularPerson(
            id: id,
            name: name ?? "",
            profilePath: profilePath,
            knownForDepartment: knownForDepartment,
            popularity: popularity ?? 0
        )
    }
}

// MARK: - TMDBPageResponse Mapping

extension TMDBPageResponse where Result == MainSearchResultDTO {

    func mapped() -> Page<MainSearchResult> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.compactMap { $0.mapped() }
        )
    }
}

extension TMDBPageResponse where Result == MainSearchPopularPersonDTO {

    func mapped() -> Page<MainSearchPopularPerson> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map { $0.mapped() }
        )
    }
}
