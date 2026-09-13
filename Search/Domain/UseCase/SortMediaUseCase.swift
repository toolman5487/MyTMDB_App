//
//  SortMediaUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SortMediaUseCase

nonisolated protocol SortMediaUseCase: Sendable {
    func callAsFunction(_ items: [MediaSummary], order: MediaSortOrder) -> [MediaSummary]
}

// MARK: - DefaultSortMediaUseCase

nonisolated struct DefaultSortMediaUseCase: SortMediaUseCase {

    // MARK: - SortMediaUseCase

    func callAsFunction(_ items: [MediaSummary], order: MediaSortOrder) -> [MediaSummary] {
        switch order {
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

    // MARK: - Private Helpers

    private static func compareDate(
        _ lhs: MediaSummary,
        _ rhs: MediaSummary,
        ascending: Bool
    ) -> Bool? {
        switch (lhs.releaseDate, rhs.releaseDate) {
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
        _ lhs: MediaSummary,
        _ rhs: MediaSummary
    ) -> Bool {
        let comparison = lhs.title.localizedStandardCompare(rhs.title)
        if comparison != .orderedSame {
            return comparison == .orderedAscending
        }

        return lhs.id < rhs.id
    }
}
