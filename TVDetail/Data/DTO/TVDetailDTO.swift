//
//  TVDetailDTO.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import Foundation

// MARK: - TVSeriesDTO

nonisolated struct TVSeriesDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let originalName: String
    let tagline: String
    let overview: String?
    let adult: Bool
    let backdropPath: String?
    let posterPath: String?
    let createdBy: [CreatorDTO]
    let episodeRunTime: [Int]
    let firstAirDate: String
    let lastAirDate: String
    let genres: [GenreDTO]
    let homepage: String?
    let inProduction: Bool
    let languages: [String]
    let lastEpisodeToAir: TVEpisodeDTO?
    let nextEpisodeToAir: TVEpisodeDTO?
    let networks: [NetworkDTO]
    let numberOfEpisodes: Int
    let numberOfSeasons: Int
    let originCountry: [String]
    let originalLanguage: String
    let popularity: Double
    let productionCompanies: [ProductionCompanyDTO]
    let productionCountries: [ProductionCountryDTO]
    let seasons: [TVSeasonDTO]
    let spokenLanguages: [SpokenLanguageDTO]
    let status: String
    let type: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case tagline
        case overview
        case adult
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case createdBy = "created_by"
        case episodeRunTime = "episode_run_time"
        case firstAirDate = "first_air_date"
        case lastAirDate = "last_air_date"
        case genres
        case homepage
        case inProduction = "in_production"
        case languages
        case lastEpisodeToAir = "last_episode_to_air"
        case nextEpisodeToAir = "next_episode_to_air"
        case networks
        case numberOfEpisodes = "number_of_episodes"
        case numberOfSeasons = "number_of_seasons"
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case popularity
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case seasons
        case spokenLanguages = "spoken_languages"
        case status
        case type
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.tagline = try container.decodeIfPresent(String.self, forKey: .tagline) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.createdBy = try container.decodeIfPresent([CreatorDTO].self, forKey: .createdBy) ?? []
        self.episodeRunTime = try container.decodeIfPresent([Int].self, forKey: .episodeRunTime) ?? []
        self.firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate) ?? ""
        self.lastAirDate = try container.decodeIfPresent(String.self, forKey: .lastAirDate) ?? ""
        self.genres = try container.decodeIfPresent([GenreDTO].self, forKey: .genres) ?? []
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.inProduction = try container.decodeIfPresent(Bool.self, forKey: .inProduction) ?? false
        self.languages = try container.decodeIfPresent([String].self, forKey: .languages) ?? []
        self.lastEpisodeToAir = try container.decodeIfPresent(TVEpisodeDTO.self, forKey: .lastEpisodeToAir)
        self.nextEpisodeToAir = try container.decodeIfPresent(TVEpisodeDTO.self, forKey: .nextEpisodeToAir)
        self.networks = try container.decodeIfPresent([NetworkDTO].self, forKey: .networks) ?? []
        self.numberOfEpisodes = try container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes) ?? 0
        self.numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons) ?? 0
        self.originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.productionCompanies = try container.decodeIfPresent(
            [ProductionCompanyDTO].self,
            forKey: .productionCompanies
        ) ?? []
        self.productionCountries = try container.decodeIfPresent(
            [ProductionCountryDTO].self,
            forKey: .productionCountries
        ) ?? []
        self.seasons = try container.decodeIfPresent([TVSeasonDTO].self, forKey: .seasons) ?? []
        self.spokenLanguages = try container.decodeIfPresent([SpokenLanguageDTO].self, forKey: .spokenLanguages) ?? []
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

nonisolated struct CreatorDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let name: String
    let originalName: String
    let gender: Int?
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case name
        case originalName = "original_name"
        case gender
        case profilePath = "profile_path"
    }
}

nonisolated struct NetworkDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String

    enum CodingKeys: String, CodingKey {
        case id
        case logoPath = "logo_path"
        case name
        case originCountry = "origin_country"
    }
}

nonisolated struct TVEpisodeDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: String
    let episodeNumber: Int
    let seasonNumber: Int
    let stillPath: String?
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名集數"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
    }
}

nonisolated struct TVSeasonDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: String
    let episodeCount: Int
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
        case seasonNumber = "season_number"
        case voteAverage = "vote_average"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名季數"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
    }
}

// MARK: - AggregateCreditsDTO

nonisolated struct AggregateCreditsDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [AggregateCastMemberDTO]
    let crew: [AggregateCrewMemberDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(
        id: Int,
        cast: [AggregateCastMemberDTO] = [],
        crew: [AggregateCrewMemberDTO] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([AggregateCastMemberDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([AggregateCrewMemberDTO].self, forKey: .crew) ?? []
    }
}

nonisolated struct AggregateCastMemberDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let gender: Int?
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let roles: [AggregateRoleDTO]
    let totalEpisodeCount: Int
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id
        case gender
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case roles
        case totalEpisodeCount = "total_episode_count"
        case order
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.roles = try container.decodeIfPresent([AggregateRoleDTO].self, forKey: .roles) ?? []
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

nonisolated struct AggregateRoleDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let character: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "credit_id"
        case character
        case episodeCount = "episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
    }
}

nonisolated struct AggregateCrewMemberDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let department: String
    let gender: Int?
    let jobs: [AggregateJobDTO]
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let totalEpisodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case department
        case gender
        case jobs
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
        case totalEpisodeCount = "total_episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.jobs = try container.decodeIfPresent([AggregateJobDTO].self, forKey: .jobs) ?? []
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
    }
}

nonisolated struct AggregateJobDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let job: String
    let episodeCount: Int

    enum CodingKeys: String, CodingKey {
        case id = "credit_id"
        case job
        case episodeCount = "episode_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount) ?? 0
    }
}
