//
//  MainHomePresentationModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - MainHomePresentationBuilder

nonisolated enum MainHomePresentationBuilder {

    static func makeSections(
        from sections: [HomeSection],
        localization: AppInterfaceLocalization
    ) -> [MainHomeSectionItem] {
        sections
            .filter { !$0.items.isEmpty }
            .sorted { lhs, rhs in
                lhs.category.displayPriority < rhs.category.displayPriority
            }
            .map { MainHomeSectionItem(section: $0, localization: localization) }
    }
}

// MARK: - MainHomeSectionItem

nonisolated struct MainHomeSectionItem: Sendable, Equatable, Identifiable {
    let id: HomeCategory
    let category: HomeCategory
    let title: String
    let contents: [HomeContentItem]

    init(section: HomeSection, localization: AppInterfaceLocalization) {
        self.id = section.category
        self.category = section.category
        self.title = section.category.title(localization: localization)
        self.contents = section.items.map { summary in
            HomeContentItem(
                summary: summary,
                mediaType: section.category.mediaType,
                localization: localization
            )
        }
    }
}

private extension HomeCategory {

    var displayPriority: Int {
        switch self {
        case .upcomingMovies:
            return 0

        case .nowPlayingMovies:
            return 1

        case .trendingMovies:
            return 2

        case .popularMovies:
            return 3

        case .topRatedMovies:
            return 4

        case .trendingTV:
            return 5

        case .popularTV:
            return 6

        case .onTheAirTV:
            return 7

        case .airingTodayTV:
            return 8

        case .topRatedTV:
            return 9
        }
    }
}
