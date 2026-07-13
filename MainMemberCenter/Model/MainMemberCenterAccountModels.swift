//
//  MainMemberCenterAccountModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - MainMemberCenterAccountMediaType

nonisolated enum MainMemberCenterAccountMediaType: String, Sendable, Encodable {
    case movie
    case tv
}

// MARK: - Account Media States

nonisolated struct AccountMediaStatesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let favorite: Bool

    init(id: Int = 0, favorite: Bool = false) {
        self.id = id
        self.favorite = favorite
    }
}

// MARK: - Account Media Favorite State

nonisolated enum AccountMediaFavoriteState: Sendable, Equatable {
    case unavailable
    case requiresUserLogin
    case ready(isFavorite: Bool)
    case updating(isFavorite: Bool)

    var isFavorite: Bool {
        switch self {
        case .unavailable, .requiresUserLogin:
            return false

        case .ready(let isFavorite), .updating(let isFavorite):
            return isFavorite
        }
    }

    var isButtonEnabled: Bool {
        switch self {
        case .unavailable, .updating:
            return false

        case .requiresUserLogin, .ready:
            return true
        }
    }
}

// MARK: - Account List Pages

typealias MainMemberCenterFavoriteMoviePage = TMDBPageResponse<MovieGridMovie>
typealias MainMemberCenterFavoriteTVPage = TMDBPageResponse<TVGridSeries>
typealias MainMemberCenterWatchlistMoviePage = TMDBPageResponse<MovieGridMovie>
typealias MainMemberCenterWatchlistTVPage = TMDBPageResponse<TVGridSeries>
typealias MainMemberCenterRatedMoviePage = TMDBPageResponse<MainMemberCenterRatedMovie>
typealias MainMemberCenterRatedTVPage = TMDBPageResponse<MainMemberCenterRatedTVSeries>
typealias MainMemberCenterRatedEpisodePage = TMDBPageResponse<MainMemberCenterRatedEpisode>
typealias MainMemberCenterListPage = TMDBPageResponse<MainMemberCenterList>

// MARK: - MainMemberCenterRatedMovie

nonisolated struct MainMemberCenterRatedMovie: Decodable, Sendable, Equatable, Identifiable {
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
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case popularity
        case rating
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未命名"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
    }
}

// MARK: - MainMemberCenterRatedTVSeries

nonisolated struct MainMemberCenterRatedTVSeries: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let firstAirDate: String?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let rating: Double

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
        case rating
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
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating) ?? 0
    }
}

// MARK: - MainMemberCenterRatedEpisode

nonisolated struct MainMemberCenterRatedEpisode: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MainMemberCenterList

nonisolated struct MainMemberCenterList: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String
    let languageCode: String
    let listType: String
    let itemCount: Int
    let favoriteCount: Int
    let posterPath: String?

    init(
        id: Int,
        name: String,
        description: String,
        languageCode: String,
        listType: String,
        itemCount: Int,
        favoriteCount: Int,
        posterPath: String?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.languageCode = languageCode
        self.listType = listType
        self.itemCount = itemCount
        self.favoriteCount = favoriteCount
        self.posterPath = posterPath
    }

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

    func replacingMissingPosterPath(with fallbackPosterPath: String?) -> MainMemberCenterList {
        guard posterPath == nil, let fallbackPosterPath else {
            return self
        }

        return MainMemberCenterList(
            id: id,
            name: name,
            description: description,
            languageCode: languageCode,
            listType: listType,
            itemCount: itemCount,
            favoriteCount: favoriteCount,
            posterPath: fallbackPosterPath
        )
    }
}

// MARK: - MainMemberCenterListDetail

nonisolated struct MainMemberCenterListDetail: Decodable, Sendable, Equatable {
    let items: [MainMemberCenterListDetailItem]

    var firstPosterPath: String? {
        items.first { $0.posterPath?.isEmpty == false }?.posterPath
    }
}

// MARK: - MainMemberCenterListDetailItem

nonisolated struct MainMemberCenterListDetailItem: Decodable, Sendable, Equatable {
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
    }
}

// MARK: - MainMemberCenterFavoriteStatusRequest

nonisolated struct MainMemberCenterFavoriteStatusRequest: Encodable, Sendable {
    let mediaType: MainMemberCenterAccountMediaType
    let mediaID: Int
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaID = "media_id"
        case favorite
    }
}

// MARK: - MainMemberCenterWatchlistStatusRequest

nonisolated struct MainMemberCenterWatchlistStatusRequest: Encodable, Sendable {
    let mediaType: MainMemberCenterAccountMediaType
    let mediaID: Int
    let watchlist: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaID = "media_id"
        case watchlist
    }
}

// MARK: - MainMemberCenterFavoriteStatusResponse

nonisolated struct MainMemberCenterFavoriteStatusResponse: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

// MARK: - MainMemberCenterWatchlistStatusResponse

nonisolated struct MainMemberCenterWatchlistStatusResponse: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
