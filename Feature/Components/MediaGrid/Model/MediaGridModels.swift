//
//  MediaGridModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MediaGridEntry

nonisolated struct MediaGridEntry: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let date: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        let decodedReleaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        let decodedFirstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = decodedTitle ?? decodedName ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.date = decodedReleaseDate ?? decodedFirstAirDate
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
    }
}

// MARK: - MediaGridItem

nonisolated struct MediaGridItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let date: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let dateText: String
    let scoreText: String

    init(entry: MediaGridEntry) {
        let date = entry.date?.isEmpty == false ? entry.date : nil

        self.id = entry.id
        self.title = entry.title
        self.overview = BaseDisplayTextFormatter.overview(entry.overview)
        self.posterURL = entry.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.date = date
        self.voteAverage = entry.voteAverage
        self.voteCount = entry.voteCount
        self.popularity = entry.popularity
        self.dateText = BaseDisplayTextFormatter.announcedText(date)
        self.scoreText = BaseDisplayTextFormatter.decimal(entry.voteAverage)
    }
}

// MARK: - MediaSortOption

nonisolated enum MediaSortOption: CaseIterable, Sendable, Hashable, Identifiable, AppSortMenuOption {
    case popularity
    case ratingHighToLow
    case ratingLowToHigh
    case newestDate
    case oldestDate
    case titleAscending
    case titleDescending

    var id: MediaSortOption {
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

        case .newestDate:
            return "最新發布"

        case .oldestDate:
            return "最早發布"

        case .titleAscending:
            return "名稱 (A → Z)"

        case .titleDescending:
            return "名稱 (Z → A)"
        }
    }

    func sorted(_ items: [MediaGridItem]) -> [MediaGridItem] {
        switch self {
        case .popularity:
            return items.sorted { lhs, rhs in
                if lhs.popularity != rhs.popularity {
                    return lhs.popularity > rhs.popularity
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingHighToLow:
            return items.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage > rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .ratingLowToHigh:
            return items.sorted { lhs, rhs in
                if lhs.voteAverage != rhs.voteAverage {
                    return lhs.voteAverage < rhs.voteAverage
                }

                if lhs.voteCount != rhs.voteCount {
                    return lhs.voteCount > rhs.voteCount
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .newestDate:
            return items.sorted { lhs, rhs in
                if let result = Self.compareDate(lhs, rhs, ascending: false) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .oldestDate:
            return items.sorted { lhs, rhs in
                if let result = Self.compareDate(lhs, rhs, ascending: true) {
                    return result
                }

                return Self.isTitleAscending(lhs, rhs)
            }

        case .titleAscending:
            return items.sorted(by: Self.isTitleAscending)

        case .titleDescending:
            return items.sorted { lhs, rhs in
                let comparison = lhs.title.localizedStandardCompare(rhs.title)
                if comparison != .orderedSame {
                    return comparison == .orderedDescending
                }

                return lhs.id < rhs.id
            }
        }
    }

    private static func compareDate(
        _ lhs: MediaGridItem,
        _ rhs: MediaGridItem,
        ascending: Bool
    ) -> Bool? {
        switch (lhs.date, rhs.date) {
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
        _ lhs: MediaGridItem,
        _ rhs: MediaGridItem
    ) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}
