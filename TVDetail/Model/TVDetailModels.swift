//
//  TVDetailModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation

// MARK: - TVDetail

nonisolated struct TVDetail: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let originalName: String
    let tagline: String
    let overview: String?
    let adult: Bool
    let backdropPath: String?
    let posterPath: String?
    let createdBy: [TVDetailCreator]
    let episodeRunTime: [Int]
    let firstAirDate: String
    let lastAirDate: String
    let genres: [TVDetailGenre]
    let homepage: String?
    let inProduction: Bool
    let languages: [String]
    let lastEpisodeToAir: TVDetailEpisode?
    let nextEpisodeToAir: TVDetailEpisode?
    let networks: [TVDetailNetwork]
    let numberOfEpisodes: Int
    let numberOfSeasons: Int
    let originCountry: [String]
    let originalLanguage: String
    let popularity: Double
    let productionCompanies: [TVDetailProductionCompany]
    let productionCountries: [TVDetailProductionCountry]
    let seasons: [TVDetailSeason]
    let spokenLanguages: [TVDetailSpokenLanguage]
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
        self.createdBy = try container.decodeIfPresent([TVDetailCreator].self, forKey: .createdBy) ?? []
        self.episodeRunTime = try container.decodeIfPresent([Int].self, forKey: .episodeRunTime) ?? []
        self.firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate) ?? ""
        self.lastAirDate = try container.decodeIfPresent(String.self, forKey: .lastAirDate) ?? ""
        self.genres = try container.decodeIfPresent([TVDetailGenre].self, forKey: .genres) ?? []
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.inProduction = try container.decodeIfPresent(Bool.self, forKey: .inProduction) ?? false
        self.languages = try container.decodeIfPresent([String].self, forKey: .languages) ?? []
        self.lastEpisodeToAir = try container.decodeIfPresent(TVDetailEpisode.self, forKey: .lastEpisodeToAir)
        self.nextEpisodeToAir = try container.decodeIfPresent(TVDetailEpisode.self, forKey: .nextEpisodeToAir)
        self.networks = try container.decodeIfPresent([TVDetailNetwork].self, forKey: .networks) ?? []
        self.numberOfEpisodes = try container.decodeIfPresent(Int.self, forKey: .numberOfEpisodes) ?? 0
        self.numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons) ?? 0
        self.originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.productionCompanies = try container.decodeIfPresent(
            [TVDetailProductionCompany].self,
            forKey: .productionCompanies
        ) ?? []
        self.productionCountries = try container.decodeIfPresent(
            [TVDetailProductionCountry].self,
            forKey: .productionCountries
        ) ?? []
        self.seasons = try container.decodeIfPresent([TVDetailSeason].self, forKey: .seasons) ?? []
        self.spokenLanguages = try container.decodeIfPresent([TVDetailSpokenLanguage].self, forKey: .spokenLanguages) ?? []
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - TVDetailContent

nonisolated struct TVDetailContent: Sendable, Equatable {
    let detail: TVDetail
    let aggregateCredits: TVAggregateCreditsResponse
    let videos: TVVideosResponse
    let images: TVImagesResponse
    let recommendations: TVRecommendationsPage
    let watchProviders: TVWatchProvidersResponse
}

// MARK: - Shared TV Detail Models

nonisolated struct TVDetailCreator: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct TVDetailGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

nonisolated struct TVDetailNetwork: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct TVDetailProductionCompany: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct TVDetailProductionCountry: Decodable, Sendable, Equatable {
    let iso3166Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case iso3166Code = "iso_3166_1"
        case name
    }
}

nonisolated struct TVDetailSpokenLanguage: Decodable, Sendable, Equatable {
    let englishName: String
    let iso639Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case iso639Code = "iso_639_1"
        case name
    }
}

nonisolated struct TVDetailEpisode: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct TVDetailSeason: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - TVAggregateCreditsResponse

nonisolated struct TVAggregateCreditsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [TVAggregateCreditCast]
    let crew: [TVAggregateCreditCrew]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(
        id: Int,
        cast: [TVAggregateCreditCast] = [],
        crew: [TVAggregateCreditCrew] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([TVAggregateCreditCast].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([TVAggregateCreditCrew].self, forKey: .crew) ?? []
    }
}

nonisolated struct TVAggregateCreditCast: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let gender: Int?
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?
    let roles: [TVAggregateCreditRole]
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
        self.roles = try container.decodeIfPresent([TVAggregateCreditRole].self, forKey: .roles) ?? []
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

nonisolated struct TVAggregateCreditRole: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct TVAggregateCreditCrew: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let department: String
    let gender: Int?
    let jobs: [TVAggregateCreditJob]
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
        self.jobs = try container.decodeIfPresent([TVAggregateCreditJob].self, forKey: .jobs) ?? []
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.totalEpisodeCount = try container.decodeIfPresent(Int.self, forKey: .totalEpisodeCount) ?? 0
    }
}

nonisolated struct TVAggregateCreditJob: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - TVVideosResponse

nonisolated struct TVVideosResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [TVVideo]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(id: Int, results: [TVVideo] = []) {
        self.id = id
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([TVVideo].self, forKey: .results) ?? []
    }
}

nonisolated struct TVVideo: Decodable, Sendable, Equatable, Identifiable {
    let id: String
    let iso639Code: String
    let iso3166Code: String
    let key: String
    let name: String
    let official: Bool
    let publishedAt: String
    let site: String
    let size: Int
    let type: String

    enum CodingKeys: String, CodingKey {
        case id
        case iso639Code = "iso_639_1"
        case iso3166Code = "iso_3166_1"
        case key
        case name
        case official
        case publishedAt = "published_at"
        case site
        case size
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(String.self, forKey: .id)
        self.iso639Code = try container.decodeIfPresent(String.self, forKey: .iso639Code) ?? ""
        self.iso3166Code = try container.decodeIfPresent(String.self, forKey: .iso3166Code) ?? ""
        self.key = try container.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名影片"
        self.official = try container.decodeIfPresent(Bool.self, forKey: .official) ?? false
        self.publishedAt = try container.decodeIfPresent(String.self, forKey: .publishedAt) ?? ""
        self.site = try container.decodeIfPresent(String.self, forKey: .site) ?? ""
        self.size = try container.decodeIfPresent(Int.self, forKey: .size) ?? 0
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
    }
}

// MARK: - TVImagesResponse

nonisolated struct TVImagesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let backdrops: [TVImage]
    let logos: [TVImage]
    let posters: [TVImage]

    enum CodingKeys: String, CodingKey {
        case id
        case backdrops
        case logos
        case posters
    }

    init(
        id: Int,
        backdrops: [TVImage] = [],
        logos: [TVImage] = [],
        posters: [TVImage] = []
    ) {
        self.id = id
        self.backdrops = backdrops
        self.logos = logos
        self.posters = posters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.backdrops = try container.decodeIfPresent([TVImage].self, forKey: .backdrops) ?? []
        self.logos = try container.decodeIfPresent([TVImage].self, forKey: .logos) ?? []
        self.posters = try container.decodeIfPresent([TVImage].self, forKey: .posters) ?? []
    }
}

nonisolated struct TVImage: Decodable, Sendable, Equatable {
    let aspectRatio: Double
    let filePath: String
    let height: Int
    let iso639Code: String?
    let voteAverage: Double
    let voteCount: Int
    let width: Int

    enum CodingKeys: String, CodingKey {
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case height
        case iso639Code = "iso_639_1"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case width
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.aspectRatio = try container.decodeIfPresent(Double.self, forKey: .aspectRatio) ?? 0
        self.filePath = try container.decodeIfPresent(String.self, forKey: .filePath) ?? ""
        self.height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
        self.iso639Code = try container.decodeIfPresent(String.self, forKey: .iso639Code)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
    }
}

// MARK: - TVRecommendationsPage

nonisolated struct TVRecommendationsPage: Decodable, Sendable, Equatable {
    let page: Int
    let results: [TVRecommendation]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }

    init(
        page: Int = 1,
        results: [TVRecommendation] = [],
        totalPages: Int = 1,
        totalResults: Int = 0
    ) {
        self.page = page
        self.results = results
        self.totalPages = totalPages
        self.totalResults = totalResults
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.results = try container.decodeIfPresent([TVRecommendation].self, forKey: .results) ?? []
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? results.count
    }
}

nonisolated struct TVRecommendation: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let genreIDs: [Int]
    let originCountry: [String]
    let originalLanguage: String
    let originalName: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let firstAirDate: String
    let name: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case adult
        case backdropPath = "backdrop_path"
        case genreIDs = "genre_ids"
        case originCountry = "origin_country"
        case originalLanguage = "original_language"
        case originalName = "original_name"
        case overview
        case popularity
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
        case name
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        self.originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - TVWatchProvidersResponse

nonisolated struct TVWatchProvidersResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [String: TVWatchProviderCountry]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(id: Int, results: [String: TVWatchProviderCountry] = [:]) {
        self.id = id
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([String: TVWatchProviderCountry].self, forKey: .results) ?? [:]
    }
}

nonisolated struct TVWatchProviderCountry: Decodable, Sendable, Equatable {
    let link: String
    let flatrate: [TVWatchProvider]
    let buy: [TVWatchProvider]
    let rent: [TVWatchProvider]
    let ads: [TVWatchProvider]
    let free: [TVWatchProvider]

    enum CodingKeys: String, CodingKey {
        case link
        case flatrate
        case buy
        case rent
        case ads
        case free
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.link = try container.decodeIfPresent(String.self, forKey: .link) ?? ""
        self.flatrate = try container.decodeIfPresent([TVWatchProvider].self, forKey: .flatrate) ?? []
        self.buy = try container.decodeIfPresent([TVWatchProvider].self, forKey: .buy) ?? []
        self.rent = try container.decodeIfPresent([TVWatchProvider].self, forKey: .rent) ?? []
        self.ads = try container.decodeIfPresent([TVWatchProvider].self, forKey: .ads) ?? []
        self.free = try container.decodeIfPresent([TVWatchProvider].self, forKey: .free) ?? []
    }
}

nonisolated struct TVWatchProvider: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let displayPriority: Int
    let logoPath: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "provider_id"
        case displayPriority = "display_priority"
        case logoPath = "logo_path"
        case name = "provider_name"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.displayPriority = try container.decodeIfPresent(Int.self, forKey: .displayPriority) ?? 0
        self.logoPath = try container.decodeIfPresent(String.self, forKey: .logoPath)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名平台"
    }
}

// MARK: - Presentation Items

nonisolated struct TVDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let overview: String?
    let posterURL: URL?
    let backdropURL: URL?
    let firstAirDateText: String?
    let lastAirDateText: String?
    let episodeRunTimeText: String?
    let seasonCountText: String?
    let episodeCountText: String?
    let scoreText: String?
    let voteCountText: String?
    let statusText: String?
    let typeText: String?
    let homepageURL: URL?

    init(detail: TVDetail) {
        self.id = detail.id
        self.title = detail.name
        self.originalTitle = detail.originalName
        self.tagline = BaseDisplayTextFormatter.nonEmptyText(detail.tagline)
        self.overview = BaseDisplayTextFormatter.nonEmptyText(detail.overview)
        self.posterURL = detail.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.backdropURL = detail.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.firstAirDateText = BaseDisplayTextFormatter.nonEmptyText(detail.firstAirDate)
        self.lastAirDateText = BaseDisplayTextFormatter.nonEmptyText(detail.lastAirDate)
        self.episodeRunTimeText = BaseDisplayTextFormatter.firstMinutes(values: detail.episodeRunTime)
        self.seasonCountText = BaseDisplayTextFormatter.count(detail.numberOfSeasons, unit: "季")
        self.episodeCountText = BaseDisplayTextFormatter.count(detail.numberOfEpisodes, unit: "集")
        self.scoreText = BaseDisplayTextFormatter.score(detail.voteAverage, voteCount: detail.voteCount)
        self.voteCountText = BaseDisplayTextFormatter.voteCount(detail.voteCount)
        self.statusText = BaseDisplayTextFormatter.nonEmptyText(detail.status)
        self.typeText = BaseDisplayTextFormatter.nonEmptyText(detail.type)
        self.homepageURL = Self.makeURL(from: detail.homepage)
    }

    private static func makeURL(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }
}

nonisolated struct TVDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let posterURL: URL?
    let backdropURL: URL?
    let scoreText: String?
    let voteCountText: String?
    let metadataText: String?

    init(detail: TVDetailItem) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = detail.tagline
        self.posterURL = detail.posterURL
        self.backdropURL = detail.backdropURL
        self.scoreText = detail.scoreText
        self.voteCountText = detail.voteCountText
        self.metadataText = BaseDisplayTextFormatter.metadata([
            detail.firstAirDateText,
            detail.seasonCountText
        ])
    }
}

nonisolated struct TVDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

nonisolated struct TVDetailAttributeSectionItem: Sendable, Equatable {
    let genres: [TVDetailAttributeItem]
    let productionCompanies: [TVDetailAttributeItem]
    let networks: [TVDetailAttributeItem]

    var isEmpty: Bool {
        genres.isEmpty && productionCompanies.isEmpty && networks.isEmpty
    }
}

nonisolated struct TVDetailAttributeItem: Sendable, Equatable, Identifiable {

    enum Kind: Sendable, Equatable {
        case genre
        case productionCompany
        case network
    }

    let id: String
    let sourceID: Int
    let title: String
    let kind: Kind

    init(genre: TVDetailGenre) {
        self.id = "genre-\(genre.id)"
        self.sourceID = genre.id
        self.title = genre.name
        self.kind = .genre
    }

    init(productionCompany: TVDetailProductionCompany) {
        self.id = "production-company-\(productionCompany.id)"
        self.sourceID = productionCompany.id
        self.title = productionCompany.name
        self.kind = .productionCompany
    }

    init(network: TVDetailNetwork) {
        self.id = "network-\(network.id)"
        self.sourceID = network.id
        self.title = network.name
        self.kind = .network
    }
}

nonisolated struct TVDetailCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let characterText: String
    let episodeCountText: String
    let profileURL: URL?

    init(cast: TVAggregateCreditCast) {
        self.id = cast.id
        self.name = cast.name
        self.characterText = Self.makeCharacterText(roles: cast.roles)
        self.episodeCountText = BaseDisplayTextFormatter.count(cast.totalEpisodeCount, unit: "集") ?? ""
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeCharacterText(roles: [TVAggregateCreditRole]) -> String {
        let characters = roles
            .map(\.character)
            .compactMap(BaseDisplayTextFormatter.nonEmptyText)

        guard !characters.isEmpty else { return "" }
        return Array(Set(characters)).sorted().joined(separator: " / ")
    }
}

nonisolated struct TVDetailSeasonItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let seasonNumber: Int
    let posterURL: URL?

    init(season: TVDetailSeason) {
        self.id = season.id
        self.title = season.name
        self.subtitle = Self.makeSubtitle(season: season)
        self.seasonNumber = season.seasonNumber
        self.posterURL = season.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeSubtitle(season: TVDetailSeason) -> String {
        BaseDisplayTextFormatter.metadata([
            season.airDate,
            BaseDisplayTextFormatter.count(season.episodeCount, unit: "集")
        ]) ?? ""
    }
}

nonisolated struct TVDetailVideoItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailURL: URL?
    let youtubeVideoKey: String?
    let videoURL: URL?

    init(video: TVVideo) {
        self.id = video.id
        self.title = video.name
        self.subtitle = video.type.isEmpty ? video.site : "\(video.type) · \(video.site)"

        if video.site.lowercased() == "youtube", !video.key.isEmpty {
            self.youtubeVideoKey = video.key
            self.thumbnailURL = URL(string: "https://img.youtube.com/vi/\(video.key)/hqdefault.jpg")
            self.videoURL = URL(string: "https://www.youtube.com/watch?v=\(video.key)")
        } else {
            self.youtubeVideoKey = nil
            self.thumbnailURL = nil
            self.videoURL = nil
        }
    }
}

nonisolated struct TVDetailRecommendationItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let firstAirDateText: String
    let scoreText: String?
    let posterURL: URL?

    init(recommendation: TVRecommendation) {
        self.id = recommendation.id
        self.title = recommendation.name
        self.firstAirDateText = recommendation.firstAirDate
        self.scoreText = BaseDisplayTextFormatter.score(
            recommendation.voteAverage,
            voteCount: recommendation.voteCount
        )
        self.posterURL = recommendation.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}
