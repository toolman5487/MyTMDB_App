//
//  EpisodeDetailDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailDTO

nonisolated struct EpisodeDetailDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let overview: String?
    let airDate: String?
    let crew: [EpisodeCrewMemberDTO]
    let episodeNumber: Int
    let guestStars: [EpisodeCastMemberDTO]
    let productionCode: String?
    let runtimeInMinutes: Int?
    let seasonNumber: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case crew
        case episodeNumber = "episode_number"
        case guestStars = "guest_stars"
        case productionCode = "production_code"
        case runtimeInMinutes = "runtime"
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        self.crew = try container.decodeIfPresent([EpisodeCrewMemberDTO].self, forKey: .crew) ?? []
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.guestStars = try container.decodeIfPresent([EpisodeCastMemberDTO].self, forKey: .guestStars) ?? []
        self.productionCode = try container.decodeIfPresent(String.self, forKey: .productionCode)
        self.runtimeInMinutes = try container.decodeIfPresent(Int.self, forKey: .runtimeInMinutes)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - Episode Credits DTOs

nonisolated struct EpisodeCreditsDTO: Decodable, Sendable {
    let id: Int
    let cast: [EpisodeCastMemberDTO]
    let crew: [EpisodeCrewMemberDTO]
    let guestStars: [EpisodeCastMemberDTO]

    private enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
        case guestStars = "guest_stars"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([EpisodeCastMemberDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([EpisodeCrewMemberDTO].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([EpisodeCastMemberDTO].self, forKey: .guestStars) ?? []
    }
}

nonisolated struct EpisodeCastMemberDTO: Decodable, Sendable {
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

nonisolated struct EpisodeCrewMemberDTO: Decodable, Sendable {
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

// MARK: - Episode Metadata DTOs

nonisolated struct EpisodeImagesDTO: Decodable, Sendable {
    let id: Int
    let stills: [MediaImageDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.stills = try container.decodeIfPresent([MediaImageDTO].self, forKey: .stills) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case stills
    }
}

nonisolated struct EpisodeExternalIDsDTO: Decodable, Sendable {
    let id: Int
    let imdbID: String?
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case imdbID = "imdb_id"
        case freebaseMID = "freebase_mid"
        case freebaseID = "freebase_id"
        case tvdbID = "tvdb_id"
        case tvrageID = "tvrage_id"
        case wikidataID = "wikidata_id"
    }
}

nonisolated struct EpisodeTranslationsDTO: Decodable, Sendable {
    let id: Int
    let translations: [EpisodeTranslationDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.translations = try container.decodeIfPresent([EpisodeTranslationDTO].self, forKey: .translations) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case translations
    }
}

nonisolated struct EpisodeTranslationDTO: Decodable, Sendable {
    let countryCode: String
    let languageCode: String
    let name: String
    let englishName: String
    let data: EpisodeTranslationContentDTO

    private enum CodingKeys: String, CodingKey {
        case countryCode = "iso_3166_1"
        case languageCode = "iso_639_1"
        case name
        case englishName = "english_name"
        case data
    }
}

nonisolated struct EpisodeTranslationContentDTO: Decodable, Sendable {
    let name: String?
    let overview: String?
}

// MARK: - Episode Account State DTOs

nonisolated struct EpisodeAccountStateDTO: Decodable, Sendable {
    let id: Int
    let rated: EpisodeRatedStateDTO

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.rated = try container.decodeIfPresent(EpisodeRatedStateDTO.self, forKey: .rated) ?? .unrated
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case rated
    }
}

nonisolated enum EpisodeRatedStateDTO: Decodable, Sendable {
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
        self = value.map(EpisodeRatedStateDTO.rated) ?? .unrated
    }
}
