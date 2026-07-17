//
//  MemberCenterAccountModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - MemberCenterAccountMediaType

nonisolated enum MemberCenterAccountMediaType: String, Sendable, Encodable {
    case movie
    case tv
}

// MARK: - Account Media States

nonisolated struct AccountMediaStatesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let favorite: Bool
    let rated: AccountMediaRatedState

    enum CodingKeys: String, CodingKey {
        case id
        case favorite
        case rated
    }

    init(
        id: Int = 0,
        favorite: Bool = false,
        rated: AccountMediaRatedState = .unrated
    ) {
        self.id = id
        self.favorite = favorite
        self.rated = rated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.favorite = try container.decodeIfPresent(Bool.self, forKey: .favorite) ?? false
        self.rated = try container.decodeIfPresent(AccountMediaRatedState.self, forKey: .rated) ?? .unrated
    }
}

// MARK: - Account Media Rated State

nonisolated enum AccountMediaRatedState: Sendable, Equatable, Decodable {
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
        self = value.map(AccountMediaRatedState.rated) ?? .unrated
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

// MARK: - Account Media Rating State

nonisolated enum AccountMediaRatingState: Sendable, Equatable {
    case unavailable
    case requiresUserLogin
    case ready(value: Double?)
    case updating(value: Double?)

    var value: Double? {
        switch self {
        case .unavailable, .requiresUserLogin:
            return nil

        case .ready(let value), .updating(let value):
            return value
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

// MARK: - Account Media Rating Value

nonisolated enum AccountMediaRatingValue {
    static let minimum = 0.5
    static let maximum = 10.0
    static let step = 0.5
    static let fallback = 8.0

    static func normalized(_ value: Double) -> Double {
        let roundedValue = (value / step).rounded() * step
        return min(max(roundedValue, minimum), maximum)
    }

    static func defaultValue(fromPublicRating publicRating: Double?) -> Double {
        guard let publicRating, publicRating > 0 else {
            return fallback
        }

        return normalized(publicRating)
    }

    static func isValid(_ value: Double) -> Bool {
        let normalizedValue = normalized(value)
        return normalizedValue == value
            && (minimum...maximum).contains(value)
    }
}

// MARK: - Account List Pages

typealias MemberCenterFavoriteMoviePage = TMDBPageResponse<MovieGridMovie>
typealias MemberCenterFavoriteTVPage = TMDBPageResponse<TVGridSeries>
typealias MemberCenterWatchlistMoviePage = TMDBPageResponse<MovieGridMovie>
typealias MemberCenterWatchlistTVPage = TMDBPageResponse<TVGridSeries>
typealias MemberCenterRatedMoviePage = TMDBPageResponse<MemberCenterRatedMovie>
typealias MemberCenterRatedTVPage = TMDBPageResponse<MemberCenterRatedTVSeries>
typealias MemberCenterRatedEpisodePage = TMDBPageResponse<MemberCenterRatedEpisode>
typealias MemberCenterListPage = TMDBPageResponse<MemberCenterList>

// MARK: - MemberCenterRatedMovie

nonisolated struct MemberCenterRatedMovie: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MemberCenterRatedTVSeries

nonisolated struct MemberCenterRatedTVSeries: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MemberCenterRatedEpisode

nonisolated struct MemberCenterRatedEpisode: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MemberCenterList

nonisolated struct MemberCenterList: Decodable, Sendable, Equatable, Identifiable {
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

    func replacingMissingPosterPath(with fallbackPosterPath: String?) -> MemberCenterList {
        guard posterPath == nil, let fallbackPosterPath else {
            return self
        }

        return MemberCenterList(
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

// MARK: - MemberCenterListDetail

nonisolated struct MemberCenterListDetail: Decodable, Sendable, Equatable {
    let items: [MemberCenterListDetailItem]

    var firstPosterPath: String? {
        items.first { $0.posterPath?.isEmpty == false }?.posterPath
    }
}

// MARK: - MemberCenterListDetailItem

nonisolated struct MemberCenterListDetailItem: Decodable, Sendable, Equatable {
    let posterPath: String?

    enum CodingKeys: String, CodingKey {
        case posterPath = "poster_path"
    }
}

// MARK: - MemberCenterFavoriteStatusRequest

nonisolated struct MemberCenterFavoriteStatusRequest: Encodable, Sendable {
    let mediaType: MemberCenterAccountMediaType
    let mediaID: Int
    let favorite: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaID = "media_id"
        case favorite
    }
}

// MARK: - MemberCenterWatchlistStatusRequest

nonisolated struct MemberCenterWatchlistStatusRequest: Encodable, Sendable {
    let mediaType: MemberCenterAccountMediaType
    let mediaID: Int
    let watchlist: Bool

    enum CodingKeys: String, CodingKey {
        case mediaType = "media_type"
        case mediaID = "media_id"
        case watchlist
    }
}

// MARK: - Account Media Rating Target

nonisolated enum AccountMediaRatingTarget: Sendable, Equatable {
    case movie(id: Int)
    case tv(seriesID: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
}

// MARK: - Account Media Rating Request

nonisolated struct AccountMediaRatingRequest: Encodable, Sendable {
    let value: Double
}

// MARK: - MemberCenterFavoriteStatusResponse

nonisolated struct MemberCenterFavoriteStatusResponse: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

// MARK: - MemberCenterWatchlistStatusResponse

nonisolated struct MemberCenterWatchlistStatusResponse: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

// MARK: - Account Media Rating Response

nonisolated struct AccountMediaRatingResponse: Decodable, Sendable, Equatable {
    let success: Bool
    let statusCode: Int
    let statusMessage: String

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
