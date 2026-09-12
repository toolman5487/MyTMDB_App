//
//  ReviewPresentationModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - ReviewFilter Presentation

extension ReviewFilter {

    var title: String {
        switch self {
        case .all:
            return "全部"

        case .rated:
            return "有評分"

        case .unrated:
            return "無評分"

        case .latest:
            return "最新評論"

        case .oldest:
            return "最舊評論"
        }
    }
}

// MARK: - DomainError Presentation

extension DomainError: ErrorMessageConvertible {

    var errorMessage: ErrorMessage {
        switch self {
        case .invalidIdentifier(let kind):
            return ErrorMessage(
                title: "找不到評論",
                message: "\(kind.displayName) ID 不正確，請返回上一頁後再試。",
                actionTitle: nil
            )
        }
    }
}

// MARK: - ReviewListPresentation

nonisolated struct ReviewListPresentation: Sendable, Equatable {
    let filters: [ReviewFilterItem]
    let reviews: [ReviewItem]
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var hasNextPage: Bool {
        page < totalPages
    }
}

// MARK: - ReviewFilterItem

nonisolated struct ReviewFilterItem: Sendable, Equatable, Identifiable {
    let id: ReviewFilter
    let title: String
    let isSelected: Bool

    init(filter: ReviewFilter, selectedFilter: ReviewFilter) {
        self.id = filter
        self.title = filter.title
        self.isSelected = filter == selectedFilter
    }
}

// MARK: - ReviewItem

nonisolated struct ReviewItem: Sendable, Equatable, Identifiable {
    let id: String
    let authorText: String
    let ratingText: String?
    let updatedDateText: String?
    let content: String
    let avatarURL: URL?

    init(review: Review) {
        self.id = review.id
        self.authorText = review.authorName
        self.ratingText = BaseDisplayTextFormatter.score(review.rating)
        self.updatedDateText = BaseDisplayTextFormatter.displayDate(from: review.updatedAt)
        self.content = review.content
        self.avatarURL = Self.makeAvatarURL(from: review.avatarPath)
    }

    private static func makeAvatarURL(from path: String?) -> URL? {
        guard let path else { return nil }

        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPath.isEmpty else { return nil }

        if trimmedPath.hasPrefix("/https://") || trimmedPath.hasPrefix("/http://") {
            return URL(string: String(trimmedPath.dropFirst()))
        }

        return APIConfig.tmdbImageURL(path: trimmedPath, size: .w185)
    }
}
