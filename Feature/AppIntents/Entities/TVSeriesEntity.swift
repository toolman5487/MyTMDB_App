//
//  TVSeriesEntity.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents
import Foundation

// MARK: - TVSeriesEntity

nonisolated struct TVSeriesEntity: AppEntity, Sendable, Equatable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "影集",
        synonyms: ["tv", "series"]
    )

    static let defaultQuery = TVSeriesEntityQuery()

    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let firstAirYear: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: displaySubtitle
        )
    }

    init(
        id: Int,
        name: String,
        originalName: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        firstAirYear: String? = nil
    ) {
        self.id = id
        self.name = name
        self.originalName = originalName
        self.overview = overview
        self.posterPath = posterPath
        self.firstAirYear = firstAirYear
    }

    init(series: MediaSummary) {
        self.init(
            id: series.id,
            name: series.title,
            overview: series.overview.isEmpty ? nil : series.overview,
            posterPath: series.posterPath,
            firstAirYear: Self.firstAirYear(from: series.releaseDate)
        )
    }

    init(detail: TVSeries) {
        self.init(
            id: detail.id,
            name: detail.name,
            originalName: detail.originalName.isEmpty ? nil : detail.originalName,
            overview: detail.overview.isEmpty ? nil : detail.overview,
            posterPath: detail.posterPath,
            firstAirYear: Self.firstAirYear(from: detail.firstAirDate)
        )
    }

    var displaySubtitle: LocalizedStringResource? {
        guard let firstAirYear else { return "影集" }
        return "\(firstAirYear) 影集"
    }

    static func firstAirYear(from date: String?) -> String? {
        guard let date, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    static func firstAirYear(from day: CalendarDay?) -> String? {
        guard let day else { return nil }
        return String(day.year)
    }
}
