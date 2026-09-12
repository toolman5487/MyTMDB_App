//
//  ReviewModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - ReviewsPage

nonisolated struct ReviewsPage: Decodable, Sendable, Equatable {
    let id: Int
    let page: Int
    let results: [Review]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case id
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.results = try container.decodeIfPresent([Review].self, forKey: .results) ?? []
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? results.count
    }
}

// MARK: - Review

nonisolated struct Review: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let author: String
    let authorDetails: ReviewAuthorDetails
    let content: String
    let createdAt: String
    let updatedAt: String
    let url: String?

    enum CodingKeys: String, CodingKey {
        case id
        case author
        case authorDetails = "author_details"
        case content
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case url
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        self.authorDetails = try container.decodeIfPresent(
            ReviewAuthorDetails.self,
            forKey: .authorDetails
        ) ?? ReviewAuthorDetails()
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
    }
}

// MARK: - ReviewAuthorDetails

nonisolated struct ReviewAuthorDetails: Decodable, Sendable, Equatable {
    let name: String
    let username: String
    let avatarPath: String?
    let rating: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case username
        case avatarPath = "avatar_path"
        case rating
    }

    init(
        name: String = "",
        username: String = "",
        avatarPath: String? = nil,
        rating: Double? = nil
    ) {
        self.name = name
        self.username = username
        self.avatarPath = avatarPath
        self.rating = rating
    }
}

// MARK: - ReviewFilter

nonisolated enum ReviewFilter: CaseIterable, Sendable, Equatable {
    case all
    case rated
    case unrated
    case latest
    case oldest

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
        self.authorText = Self.makeAuthorText(review: review)
        self.ratingText = Self.makeRatingText(rating: review.authorDetails.rating)
        self.updatedDateText = Self.makeDateText(from: review.updatedAt)
        self.content = review.content.trimmingCharacters(in: .whitespacesAndNewlines)
        self.avatarURL = Self.makeAvatarURL(from: review.authorDetails.avatarPath)
    }

    private static func makeAuthorText(review: Review) -> String {
        let displayName = review.authorDetails.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !displayName.isEmpty {
            return displayName
        }

        let username = review.authorDetails.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !username.isEmpty {
            return username
        }

        return review.author.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func makeRatingText(rating: Double?) -> String? {
        BaseDisplayTextFormatter.score(rating)
    }

    private static func makeDateText(from rawValue: String) -> String? {
        BaseDisplayTextFormatter.iso8601DisplayDate(from: rawValue)
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
