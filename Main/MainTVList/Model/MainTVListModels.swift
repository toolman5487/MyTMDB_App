//
//  MainTVListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MainTVGenreResponse

nonisolated struct MainTVGenreResponse: Decodable, Sendable, Equatable {
    let genres: [MainTVGenre]
}

// MARK: - MainTVGenre

nonisolated struct MainTVGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - TVGridSeries

nonisolated struct TVGridSeries: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
    }
}

// MARK: - TVGridSeriesItem

nonisolated struct TVGridSeriesItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let firstAirDateText: String
    let scoreText: String

    init(series: TVGridSeries) {
        let firstAirDate = series.firstAirDate?.isEmpty == false ? series.firstAirDate : nil

        self.id = series.id
        self.title = series.name
        self.overview = BaseDisplayTextFormatter.overview(series.overview)
        self.posterURL = series.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.firstAirDate = firstAirDate
        self.voteAverage = series.voteAverage
        self.voteCount = series.voteCount
        self.popularity = series.popularity
        self.firstAirDateText = BaseDisplayTextFormatter.announcedText(firstAirDate)
        self.scoreText = BaseDisplayTextFormatter.decimal(series.voteAverage)
    }
}

// MARK: - MainTVListSeriesPage

nonisolated struct MainTVListSeriesPage: Sendable, Equatable {
    let genreID: Int
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let series: [TVGridSeries]
}

// MARK: - MainTVGenreItem

nonisolated struct MainTVGenreItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let isSelected: Bool

    init(
        genre: MainTVGenre,
        isSelected: Bool
    ) {
        self.id = genre.id
        self.name = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: genre.name)
        self.isSelected = isSelected
    }
}

// MARK: - TVSortOption

nonisolated enum TVSortOption: CaseIterable, Sendable, Hashable, Identifiable, AppSortMenuOption {
    case popularity
    case ratingHighToLow
    case ratingLowToHigh
    case newestFirstAirDate
    case oldestFirstAirDate
    case titleAscending
    case titleDescending

    var id: TVSortOption {
        self
    }

    var title: String {
        switch self {
        case .popularity:
            return "人氣最高"

        case .ratingHighToLow:
            return "評分最高"

        case .ratingLowToHigh:
            return "評分最低"

        case .newestFirstAirDate:
            return "最新開播"

        case .oldestFirstAirDate:
            return "最早開播"

        case .titleAscending:
            return "名稱 (A → Z)"

        case .titleDescending:
            return "名稱 (Z → A)"
        }
    }

    func sorted(_ series: [TVGridSeriesItem]) -> [TVGridSeriesItem] {
        switch self {
        case .popularity:
            return series.sorted { lhs, rhs in
                if lhs.popularity != rhs.popularity {
                    return lhs.popularity > rhs.popularity
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingHighToLow:
            return series.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage > rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingLowToHigh:
            return series.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage < rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .newestFirstAirDate:
            return series.sorted { lhs, rhs in
                if let result = Self.compareFirstAirDate(lhs, rhs, ascending: false) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .oldestFirstAirDate:
            return series.sorted { lhs, rhs in
                if let result = Self.compareFirstAirDate(lhs, rhs, ascending: true) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .titleAscending:
            return series.sorted(by: Self.isTitleAscending)

        case .titleDescending:
            return series.sorted { lhs, rhs in
                let comparison = lhs.title.localizedStandardCompare(rhs.title)
                if comparison != .orderedSame {
                    return comparison == .orderedDescending
                }

                return lhs.id < rhs.id
            }
        }
    }

    private static func compareFirstAirDate(
        _ lhs: TVGridSeriesItem,
        _ rhs: TVGridSeriesItem,
        ascending: Bool
    ) -> Bool? {
        switch (lhs.firstAirDate, rhs.firstAirDate) {
        case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
            return ascending ? lhsDate < rhsDate : lhsDate > rhsDate

        case (.some, nil):
            return true

        case (nil, .some):
            return false

        default:
            return nil
        }
    }

    private static func isTitleAscending(
        _ lhs: TVGridSeriesItem,
        _ rhs: TVGridSeriesItem
    ) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}

// MARK: - MainTVListContent

nonisolated struct MainTVListContent: Sendable, Equatable {
    let genres: [MainTVGenreItem]
    let selectedGenre: MainTVGenreItem
    let series: [TVGridSeriesItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool
    let selectedSortOption: TVSortOption?

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MainTVListContent {
        MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading,
            selectedSortOption: selectedSortOption
        )
    }

    func appending(page: MainTVListSeriesPage) -> MainTVListContent {
        let nextSeries = series + page.series.map(TVGridSeriesItem.init(series:))

        return MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: nextSeries,
            currentPage: page.page,
            totalPages: page.totalPages,
            totalResults: page.totalResults,
            isLoadingNextPage: false,
            selectedSortOption: selectedSortOption
        )
    }

    func updatingSortOption(_ option: TVSortOption) -> MainTVListContent {
        MainTVListContent(
            genres: genres,
            selectedGenre: selectedGenre,
            series: series,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoadingNextPage,
            selectedSortOption: option
        )
    }
}
