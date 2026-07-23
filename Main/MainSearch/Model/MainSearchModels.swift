//
//  MainSearchModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import Foundation

// MARK: - MainSearchMediaType

nonisolated enum MainSearchMediaType: String, Decodable, Sendable, Equatable {
    case movie
    case tv
    case person
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        self = MainSearchMediaType(rawValue: value) ?? .unknown
    }

    var title: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "劇集"

        case .person:
            return "人物"

        case .unknown:
            return "未知"
        }
    }

}

// MARK: - MainSearchFilter

nonisolated enum MainSearchFilter: String, CaseIterable, Sendable, Equatable, Identifiable {
    case all
    case movie
    case tv
    case person

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all:
            return "全部"

        case .movie:
            return MainSearchMediaType.movie.title

        case .tv:
            return MainSearchMediaType.tv.title

        case .person:
            return MainSearchMediaType.person.title
        }
    }

    var mediaType: MainSearchMediaType? {
        switch self {
        case .all:
            return nil

        case .movie:
            return .movie

        case .tv:
            return .tv

        case .person:
            return .person
        }
    }
}

// MARK: - MainSearchResult

nonisolated struct MainSearchResult: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let mediaType: MainSearchMediaType
    let title: String
    let overview: String
    let posterPath: String?
    let profilePath: String?
    let primaryDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let knownForDepartment: String?

    enum CodingKeys: String, CodingKey {
        case id
        case mediaType = "media_type"
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case profilePath = "profile_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case knownForDepartment = "known_for_department"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.mediaType = try container.decodeIfPresent(MainSearchMediaType.self, forKey: .mediaType) ?? .unknown
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.primaryDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
    }
}

// MARK: - MainSearchResultPage

nonisolated struct MainSearchResultPage: Sendable, Equatable {
    let keyword: String
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [MainSearchResult]
}

// MARK: - MainSearchContent

nonisolated struct MainSearchContent: Sendable, Equatable {
    let keyword: String
    let allResults: [MainSearchResultItem]
    let selectedFilter: MainSearchFilter
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var results: [MainSearchResultItem] {
        guard let mediaType = selectedFilter.mediaType else {
            return allResults
        }

        return allResults.filter { $0.mediaType == mediaType }
    }

    var filters: [MainSearchFilterItem] {
        MainSearchFilter.allCases.map { filter in
            MainSearchFilterItem(filter: filter, isSelected: filter == selectedFilter)
        }
    }

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: allResults,
            selectedFilter: selectedFilter,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(page: MainSearchResultPage) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: Self.uniqueResults(allResults + page.results.map(MainSearchResultItem.init(result:))),
            selectedFilter: selectedFilter,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false
        )
    }

    func selectingFilter(_ filter: MainSearchFilter) -> MainSearchContent {
        MainSearchContent(
            keyword: keyword,
            allResults: allResults,
            selectedFilter: filter,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage
        )
    }

    static func uniqueResults(_ results: [MainSearchResultItem]) -> [MainSearchResultItem] {
        var seenIDs = Set<String>()
        return results.filter { result in
            seenIDs.insert(result.id).inserted
        }
    }
}

// MARK: - MainSearchFilterItem

nonisolated struct MainSearchFilterItem: Sendable, Equatable, Identifiable {
    let filter: MainSearchFilter
    let isSelected: Bool

    var id: String {
        filter.id
    }

    var title: String {
        filter.title
    }
}

// MARK: - MainSearchResultItem

nonisolated struct MainSearchResultItem: Sendable, Equatable, Identifiable {
    let id: String
    let sourceID: Int
    let mediaType: MainSearchMediaType
    let title: String
    let subtitle: String?
    let imageURL: URL?
    let popularity: Double

    init(result: MainSearchResult) {
        self.id = "\(result.mediaType.rawValue)-\(result.id)"
        self.sourceID = result.id
        self.mediaType = result.mediaType
        self.title = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: result.title)
        self.subtitle = Self.makeSubtitle(for: result)
        self.imageURL = Self.makeImageURL(for: result)
        self.popularity = result.popularity
    }

    private static func makeSubtitle(for result: MainSearchResult) -> String? {
        switch result.mediaType {
        case .movie, .tv:
            return BaseDisplayTextFormatter.metadata([
                BaseDisplayTextFormatter.year(from: result.primaryDate),
                BaseDisplayTextFormatter.ratingText(result.voteAverage)
            ])

        case .person:
            return BaseDisplayTextFormatter.nonEmptyText(result.knownForDepartment)

        case .unknown:
            return nil
        }
    }

    private static func makeImageURL(for result: MainSearchResult) -> URL? {
        switch result.mediaType {
        case .movie, .tv:
            return result.posterPath.flatMap {
                APIConfig.tmdbImageURL(path: $0, size: .w185)
            }

        case .person:
            return result.profilePath.flatMap {
                APIConfig.tmdbImageURL(path: $0, size: .w185)
            }

        case .unknown:
            return nil
        }
    }
}
