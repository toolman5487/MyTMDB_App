//
//  MainMemberCenterPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MainMemberCenterPresentationBuilder

nonisolated enum MainMemberCenterPresentationBuilder {

    private enum Configuration {
        static let previewItemLimit = 10
    }

    static func makeContent(from snapshot: MainMemberCenterContentSnapshot) -> MainMemberCenterContent {
        MainMemberCenterContent(
            profile: snapshot.profile,
            contentSections: makeSections(from: snapshot.previewPages)
        )
    }

    static func makeGuestContent() -> MainMemberCenterGuestContent {
        MainMemberCenterGuestContent(
            profile: .guest,
            loginPrompt: MainMemberCenterGuestLoginPrompt(
                title: "登入帳號",
                message: "登入後同步收藏、電影清單、評分內容。",
                systemImageName: "person.crop.circle.badge.plus",
                actionTitle: "前往登入"
            )
        )
    }

    static func makeSections(from previewPages: [MainMemberCenterPreviewPage]) -> [MainMemberCenterSection] {
        previewPages.compactMap(makeSection)
    }

    static func makeItems(
        from movies: [MovieGridMovie],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        movies.map {
            MainMemberCenterListItem(movie: $0, destination: destination)
        }
    }

    static func makeItems(
        from series: [TVGridSeries],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        series.map {
            MainMemberCenterListItem(series: $0, destination: destination)
        }
    }

    static func makeItems(
        from movies: [MainMemberCenterRatedMovie],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        movies.map {
            MainMemberCenterListItem(movie: $0, destination: destination)
        }
    }

    static func makeItems(
        from series: [MainMemberCenterRatedTVSeries],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        series.map {
            MainMemberCenterListItem(series: $0, destination: destination)
        }
    }

    static func makeItems(
        from episodes: [MainMemberCenterRatedEpisode],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        episodes.map {
            MainMemberCenterListItem(episode: $0, destination: destination)
        }
    }

    static func makeItems(
        from lists: [MainMemberCenterList],
        destination: MainMemberCenterDestination
    ) -> [MainMemberCenterListItem] {
        lists.map {
            MainMemberCenterListItem(list: $0, destination: destination)
        }
    }

    private static func makeSection(from previewPage: MainMemberCenterPreviewPage) -> MainMemberCenterSection? {
        let destination = previewPage.destination
        let items: [MainMemberCenterListItem]

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

        return MainMemberCenterSection(
            destination: destination,
            items: items
        )
    }
}
