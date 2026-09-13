//
//  SeasonDetailDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - SeasonDetailDTO

nonisolated struct SeasonDetailDTO: Decodable, Sendable {
    let id: Int
    let tmdbInternalID: String?
    let name: String?
    let overview: String?
    let airDate: String?
    let episodes: [SeasonEpisodeDTO]
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double

    private enum CodingKeys: String, CodingKey {
        case id
        case tmdbInternalID = "_id"
        case name
        case overview
        case airDate = "air_date"
        case episodes
        case posterPath = "poster_path"
        case seasonNumber = "season_number"
        case voteAverage = "vote_average"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.tmdbInternalID = try container.decodeIfPresent(String.self, forKey: .tmdbInternalID)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        self.episodes = try container.decodeIfPresent([SeasonEpisodeDTO].self, forKey: .episodes) ?? []
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
    }
}

// MARK: - SeasonEpisodeDTO

nonisolated struct SeasonEpisodeDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let overview: String?
    let airDate: String?
    let episodeNumber: Int
    let episodeType: String?
    let productionCode: String?
    let runtimeInMinutes: Int?
    let seasonNumber: Int
    let showID: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
    let crew: [SeasonEpisodeCrewMemberDTO]
    let guestStars: [SeasonEpisodeGuestStarDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case episodeType = "episode_type"
        case productionCode = "production_code"
        case runtimeInMinutes = "runtime"
        case seasonNumber = "season_number"
        case showID = "show_id"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case crew
        case guestStars = "guest_stars"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.episodeType = try container.decodeIfPresent(String.self, forKey: .episodeType)
        self.productionCode = try container.decodeIfPresent(String.self, forKey: .productionCode)
        self.runtimeInMinutes = try container.decodeIfPresent(Int.self, forKey: .runtimeInMinutes)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.showID = try container.decodeIfPresent(Int.self, forKey: .showID) ?? 0
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.crew = try container.decodeIfPresent([SeasonEpisodeCrewMemberDTO].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([SeasonEpisodeGuestStarDTO].self, forKey: .guestStars) ?? []
    }
}

// MARK: - Episode People DTOs

nonisolated struct SeasonEpisodeCrewMemberDTO: Decodable, Sendable {
    let id: Int
    let creditID: String?
    let department: String?
    let job: String?
    let name: String?
    let originalName: String?
    let profilePath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case department
        case job
        case name
        case originalName = "original_name"
        case profilePath = "profile_path"
    }
}

nonisolated struct SeasonEpisodeGuestStarDTO: Decodable, Sendable {
    let id: Int
    let character: String?
    let creditID: String?
    let name: String?
    let order: Int?
    let profilePath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case character
        case creditID = "credit_id"
        case name
        case order
        case profilePath = "profile_path"
    }
}

// MARK: - Season Credits DTOs

nonisolated struct SeasonCreditsDTO: Decodable, Sendable {
    let id: Int
    let cast: [SeasonCreditCastDTO]
    let crew: [SeasonCreditCrewDTO]
    let guestStars: [SeasonCreditCastDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
        case guestStars = "guest_stars"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([SeasonCreditCastDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([SeasonCreditCrewDTO].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([SeasonCreditCastDTO].self, forKey: .guestStars) ?? []
    }
}

nonisolated struct SeasonCreditCastDTO: Decodable, Sendable {
    let id: Int
    let character: String?
    let creditID: String?
    let name: String?
    let order: Int?
    let profilePath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case character
        case creditID = "credit_id"
        case name
        case order
        case profilePath = "profile_path"
    }
}

nonisolated struct SeasonCreditCrewDTO: Decodable, Sendable {
    let id: Int
    let creditID: String?
    let department: String?
    let job: String?
    let name: String?
    let profilePath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case department
        case job
        case name
        case profilePath = "profile_path"
    }
}

// MARK: - Season Metadata DTOs

nonisolated struct SeasonExternalIDsDTO: Decodable, Sendable {
    let id: Int
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case freebaseMID = "freebase_mid"
        case freebaseID = "freebase_id"
        case tvdbID = "tvdb_id"
        case tvrageID = "tvrage_id"
        case wikidataID = "wikidata_id"
    }
}

nonisolated struct SeasonTranslationsDTO: Decodable, Sendable {
    let id: Int
    let translations: [SeasonTranslationDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.translations = try container.decodeIfPresent([SeasonTranslationDTO].self, forKey: .translations) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case translations
    }
}

nonisolated struct SeasonTranslationDTO: Decodable, Sendable {
    let countryCode: String
    let languageCode: String
    let name: String
    let englishName: String
    let data: SeasonTranslationContentDTO

    private enum CodingKeys: String, CodingKey {
        case countryCode = "iso_3166_1"
        case languageCode = "iso_639_1"
        case name
        case englishName = "english_name"
        case data
    }
}

nonisolated struct SeasonTranslationContentDTO: Decodable, Sendable {
    let name: String?
    let overview: String?
    let homepage: String?
}

// MARK: - Season Account State DTOs

nonisolated struct SeasonAccountStateDTO: Decodable, Sendable {
    let id: Int
    let rated: SeasonRatedStateDTO

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.rated = try container.decodeIfPresent(SeasonRatedStateDTO.self, forKey: .rated) ?? .unrated
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case rated
    }
}

nonisolated enum SeasonRatedStateDTO: Decodable, Sendable {
    case unrated
    case rated(Double)

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
        self = value.map(SeasonRatedStateDTO.rated) ?? .unrated
    }
}
