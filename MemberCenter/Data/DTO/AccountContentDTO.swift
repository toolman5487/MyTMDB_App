//
//  AccountContentDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - RatedMediaDTO

nonisolated struct RatedMediaDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let rating: Double

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
        case rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
    }
}

// MARK: - RatedEpisodeDTO

nonisolated struct RatedEpisodeDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let showID: Int
    let seasonNumber: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let airDate: String?
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
    let rating: Double

    enum CodingKeys: String, CodingKey {
        case id
        case showID = "show_id"
        case seasonNumber = "season_number"
        case episodeNumber = "episode_number"
        case name
        case overview
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.showID = try container.decode(Int.self, forKey: .showID)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
    }
}

// MARK: - AccountListDTO

nonisolated struct AccountListDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let languageCode: String
    let listType: String
    let itemCount: Int
    let favoriteCount: Int
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case languageCode = "iso_639_1"
        case listType = "list_type"
        case itemCount = "item_count"
        case favoriteCount = "favorite_count"
        case posterPath = "poster_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名片單"
        self.description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        self.languageCode = try container.decodeIfPresent(String.self, forKey: .languageCode) ?? ""
        self.listType = try container.decodeIfPresent(String.self, forKey: .listType) ?? ""
        self.itemCount = try container.decodeIfPresent(Int.self, forKey: .itemCount) ?? 0
        self.favoriteCount = try container.decodeIfPresent(Int.self, forKey: .favoriteCount) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
    }
}

// MARK: - AccountListDetailDTO

nonisolated struct AccountListDetailDTO: Decodable, Sendable, Equatable {
    let items: [AccountListDetailItemDTO]

    var firstPosterPath: String? {
        items.first { $0.posterPath?.isEmpty == false }?.posterPath
    }
}

// MARK: - AccountListDetailItemDTO

nonisolated struct AccountListDetailItemDTO: Decodable, Sendable, Equatable {
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
    }
}
