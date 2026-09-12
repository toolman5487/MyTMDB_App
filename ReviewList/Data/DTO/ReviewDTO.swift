//
//  ReviewDTO.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - ReviewsPageDTO

nonisolated struct ReviewsPageDTO: Decodable, Sendable, Equatable {
    let id: Int
    let page: Int
    let results: [ReviewDTO]
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
        self.results = try container.decodeIfPresent([ReviewDTO].self, forKey: .results) ?? []
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? results.count
    }
}

// MARK: - ReviewDTO

nonisolated struct ReviewDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let author: String
    let authorDetails: ReviewAuthorDetailsDTO
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
            ReviewAuthorDetailsDTO.self,
            forKey: .authorDetails
        ) ?? ReviewAuthorDetailsDTO()
        self.content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt) ?? ""
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
    }
}

// MARK: - ReviewAuthorDetailsDTO

nonisolated struct ReviewAuthorDetailsDTO: Decodable, Sendable, Equatable {
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
