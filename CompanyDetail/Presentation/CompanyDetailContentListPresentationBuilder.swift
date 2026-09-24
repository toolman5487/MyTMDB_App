//
//  CompanyDetailContentListPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailContentListPresentationBuilder

nonisolated enum CompanyDetailContentListPresentationBuilder {

    static func makeContentListConfiguration(
        content: CompanyDetailContent,
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) -> DetailContentListConfiguration? {
        let page = page(for: mediaKind, content: content)

        guard !page.items.isEmpty else { return nil }

        return DetailContentListConfiguration(
            title: title(for: mediaKind, localization: localization),
            thumbnailStyle: .portrait,
            items: page.items.map {
                makeItem(summary: $0, mediaKind: mediaKind, localization: localization)
            }
        )
    }

    private static func page(
        for mediaKind: MediaKind,
        content: CompanyDetailContent
    ) -> Page<MediaSummary> {
        switch mediaKind {
        case .movie:
            return content.movies

        case .tv:
            return content.tvShows
        }
    }

    private static func title(
        for mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) -> String {
        switch mediaKind {
        case .movie:
            return localization.string("company_detail.section.movies", defaultValue: "Movies")

        case .tv:
            return localization.string("company_detail.section.tv_shows", defaultValue: "TV Shows")
        }
    }

    static func makeItem(
        summary: MediaSummary,
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) -> DetailContentListItem {
        DetailContentListItem(
            id: "\(mediaKind.rawValue)-\(summary.id)",
            imageURL: summary.posterPath.flatMap {
                TMDBResourceURL.image(path: $0, size: .w185)
            },
            title: BaseDisplayTextFormatter.text(
                summary.title,
                fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
            ),
            subtitle: BaseDisplayTextFormatter.metadata([
                BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate),
                BaseDisplayTextFormatter.score(summary.voteAverage, voteCount: summary.voteCount)
            ]),
            destination: destination(for: mediaKind, id: summary.id)
        )
    }

    private static func destination(
        for mediaKind: MediaKind,
        id: Int
    ) -> DetailContentListDestination {
        switch mediaKind {
        case .movie:
            return .movie(id: id)

        case .tv:
            return .tv(seriesID: id)
        }
    }
}
