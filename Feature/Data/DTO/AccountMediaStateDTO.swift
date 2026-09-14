//
//  AccountMediaStateDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - AccountMediaStatesDTO

nonisolated struct AccountMediaStatesDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let favorite: Bool
    let rated: AccountMediaRatedStateDTO

    enum CodingKeys: String, CodingKey {
        case id
        case favorite
        case rated
    }

    init(
        id: Int = 0,
        favorite: Bool = false,
        rated: AccountMediaRatedStateDTO = .unrated
    ) {
        self.id = id
        self.favorite = favorite
        self.rated = rated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.favorite = try container.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        self.rated = try container.decodeIfPresent(AccountMediaRatedStateDTO.self, forKey: .rated) ?? .unrated
    }
}

// MARK: - AccountMediaRatedStateDTO

nonisolated enum AccountMediaRatedStateDTO: Sendable, Equatable, Decodable {
    case unrated
    case rated(Double)

    var value: Double? {
        switch self {
        case .unrated:
            return nil

        case .rated(let value):
            return value
        }
    }

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let singleValueContainer = try decoder.singleValueContainer()

        if (try? singleValueContainer.decode(Bool.self)) != nil {
            self = .unrated
            return
        }

        if let rating = try? singleValueContainer.decode(Double.self) {
            self = .rated(rating)
            return
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)
        let value = try container.decodeIfPresent(Double.self, forKey: .value)
        self = value.map(AccountMediaRatedStateDTO.rated) ?? .unrated
    }
}

// MARK: - AccountStatusResponseDTO

nonisolated struct AccountStatusResponseDTO: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

// MARK: - AccountFavoriteRequestDTO

nonisolated struct AccountFavoriteRequestDTO: Encodable, Sendable {
    let mediaType: MediaKind
    let mediaID: Int
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaID = "media_id"
        case favorite
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(mediaType.rawValue, forKey: .mediaType)
        try container.encode(mediaID, forKey: .mediaID)
        try container.encode(favorite, forKey: .favorite)
    }
}

// MARK: - AccountRatingRequestDTO

nonisolated struct AccountRatingRequestDTO: Encodable, Sendable {
    let value: Double
}
