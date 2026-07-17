//
//  MemberCenterPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterPresentationBuilder

nonisolated enum MemberCenterPresentationBuilder {

    private enum Configuration {
        static let previewItemLimit = 10
    }

    static func makeContent(from snapshot: MemberCenterContentSnapshot) -> MemberCenterContent {
        MemberCenterContent(
            profile: snapshot.profile,
            contentSections: makeSections(from: snapshot.previewPages)
        )
    }

    static func makeGuestContent() -> MemberCenterGuestContent {
        MemberCenterGuestContent(
            profile: .guest,
            loginPrompt: MemberCenterGuestLoginPrompt(
                title: "登入帳號",
                message: "登入後同步收藏、電影清單、評分內容。",
                systemImageName: "person.crop.circle.badge.plus",
                actionTitle: "前往登入"
            )
        )
    }

    static func makeSections(from previewPages: [MemberCenterPreviewPage]) -> [MemberCenterSection] {
        previewPages.compactMap(makeSection)
    }

    static func makeItems(
        from movies: [MovieGridMovie],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        movies.map {
            MemberCenterListItem(movie: $0, destination: destination)
        }
    }

    static func makeItems(
        from series: [TVGridSeries],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        series.map {
            MemberCenterListItem(series: $0, destination: destination)
        }
    }

    static func makeItems(
        from movies: [MemberCenterRatedMovie],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        movies.map {
            MemberCenterListItem(movie: $0, destination: destination)
        }
    }

    static func makeItems(
        from series: [MemberCenterRatedTVSeries],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        series.map {
            MemberCenterListItem(series: $0, destination: destination)
        }
    }

    static func makeItems(
        from episodes: [MemberCenterRatedEpisode],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        episodes.map {
            MemberCenterListItem(episode: $0, destination: destination)
        }
    }

    static func makeItems(
        from lists: [MemberCenterList],
        destination: MemberCenterDestination
    ) -> [MemberCenterListItem] {
        lists.map {
            MemberCenterListItem(list: $0, destination: destination)
        }
    }

    private static func makeSection(from previewPage: MemberCenterPreviewPage) -> MemberCenterSection? {
        let destination = previewPage.destination
        let items: [MemberCenterListItem]

        switch previewPage {
        case .favoriteMovies(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .favoriteTV(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .watchlistMovies(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .watchlistTV(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .ratedMovies(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .ratedTV(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .ratedEpisodes(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )

        case .lists(let page):
            items = makeItems(
                from: Array(page.results.prefix(Configuration.previewItemLimit)),
                destination: destination
            )
        }

        guard !items.isEmpty else { return nil }

        return MemberCenterSection(
            destination: destination,
            items: items
        )
    }
}
