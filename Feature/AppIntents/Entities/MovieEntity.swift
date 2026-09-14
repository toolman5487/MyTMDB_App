//
//  MovieEntity.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents
import Foundation

// MARK: - MovieEntity

nonisolated struct MovieEntity: AppEntity, Sendable, Equatable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "電影",
        synonyms: ["movie", "film"]
    )

    static let defaultQuery = MovieEntityQuery()

    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let releaseYear: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: displaySubtitle
        )
    }

    init(
        id: Int,
        title: String,
        originalTitle: String? = nil,
        overview: String? = nil,
        posterPath: String? = nil,
        releaseYear: String? = nil
    ) {
        self.id = id
        self.title = title
        self.originalTitle = originalTitle
        self.overview = overview
        self.posterPath = posterPath
        self.releaseYear = releaseYear
    }

    init(movie: MediaSummary) {
        self.init(
            id: movie.id,
            title: BaseDisplayTextFormatter.text(movie.title, fallback: "未命名"),
            overview: movie.overview.isEmpty ? nil : movie.overview,
            posterPath: movie.posterPath,
            releaseYear: Self.releaseYear(from: movie.releaseDate)
        )
    }

    init(detail: Movie) {
        self.init(
            id: detail.id,
            title: BaseDisplayTextFormatter.text(detail.title, fallback: "未命名"),
            originalTitle: detail.originalTitle.isEmpty ? nil : detail.originalTitle,
            overview: detail.overview.isEmpty ? nil : detail.overview,
            posterPath: detail.posterPath,
            releaseYear: Self.releaseYear(from: detail.releaseDate)
        )
    }

    var displaySubtitle: LocalizedStringResource? {
        guard let releaseYear else { return "電影" }
        return "\(releaseYear) 電影"
    }

    static func releaseYear(from date: String?) -> String? {
        guard let date, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }

    static func releaseYear(from day: CalendarDay?) -> String? {
        guard let day else { return nil }
        return String(day.year)
    }
}
