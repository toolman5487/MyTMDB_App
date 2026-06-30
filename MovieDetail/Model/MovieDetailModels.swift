//
//  MovieDetailModels.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - MovieDetail

nonisolated struct MovieDetail: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String
    let overview: String
    let adult: Bool
    let video: Bool
    let backdropPath: String?
    let posterPath: String?
    let belongsToCollection: MovieDetailCollection?
    let budget: Int
    let genres: [MovieDetailGenre]
    let homepage: String?
    let imdbID: String?
    let originalLanguage: String
    let originCountry: [String]
    let popularity: Double
    let productionCompanies: [MovieDetailProductionCompany]
    let productionCountries: [MovieDetailProductionCountry]
    let releaseDate: String
    let revenue: Int
    let runtime: Int?
    let spokenLanguages: [MovieDetailSpokenLanguage]
    let status: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case tagline
        case overview
        case adult
        case video
        case backdropPath = "backdrop_path"
        case posterPath = "poster_path"
        case belongsToCollection = "belongs_to_collection"
        case budget
        case genres
        case homepage
        case imdbID = "imdb_id"
        case originalLanguage = "original_language"
        case originCountry = "origin_country"
        case popularity
        case productionCompanies = "production_companies"
        case productionCountries = "production_countries"
        case releaseDate = "release_date"
        case revenue
        case runtime
        case spokenLanguages = "spoken_languages"
        case status
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未命名"
        self.originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle) ?? title
        self.tagline = try container.decodeIfPresent(String.self, forKey: .tagline) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.belongsToCollection = try container.decodeIfPresent(MovieDetailCollection.self, forKey: .belongsToCollection)
        self.budget = try container.decodeIfPresent(Int.self, forKey: .budget) ?? 0
        self.genres = try container.decodeIfPresent([MovieDetailGenre].self, forKey: .genres) ?? []
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.imdbID = try container.decodeIfPresent(String.self, forKey: .imdbID)
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.productionCompanies = try container.decodeIfPresent(
            [MovieDetailProductionCompany].self,
            forKey: .productionCompanies
        ) ?? []
        self.productionCountries = try container.decodeIfPresent(
            [MovieDetailProductionCountry].self,
            forKey: .productionCountries
        ) ?? []
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? ""
        self.revenue = try container.decodeIfPresent(Int.self, forKey: .revenue) ?? 0
        self.runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        self.spokenLanguages = try container.decodeIfPresent([MovieDetailSpokenLanguage].self, forKey: .spokenLanguages) ?? []
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - MovieDetailCollection

nonisolated struct MovieDetailCollection: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let posterPath: String?
    let backdropPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
    }
}

// MARK: - MovieDetailGenre

nonisolated struct MovieDetailGenre: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - MovieDetailProductionCompany

nonisolated struct MovieDetailProductionCompany: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MovieDetailProductionCountry

nonisolated struct MovieDetailProductionCountry: Decodable, Sendable, Equatable {
    let iso3166Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case iso3166Code = "iso_3166_1"
        case name
    }
}

// MARK: - MovieDetailSpokenLanguage

nonisolated struct MovieDetailSpokenLanguage: Decodable, Sendable, Equatable {
    let englishName: String
    let iso639Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case iso639Code = "iso_639_1"
        case name
    }
}

// MARK: - MovieDetailContent

nonisolated struct MovieDetailContent: Sendable, Equatable {
    let detail: MovieDetail
    let credits: MovieCreditsResponse
    let videos: MovieVideosResponse
    let images: MovieImagesResponse
    let recommendations: MovieRecommendationsPage
    let watchProviders: MovieWatchProvidersResponse
}

// MARK: - MovieCreditsResponse

nonisolated struct MovieCreditsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [MovieCreditCast]
    let crew: [MovieCreditCrew]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([MovieCreditCast].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([MovieCreditCrew].self, forKey: .crew) ?? []
    }
}

// MARK: - MovieCreditCast

nonisolated struct MovieCreditCast: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let castID: Int?
    let character: String
    let creditID: String
    let gender: Int?
    let knownForDepartment: String
    let name: String
    let order: Int
    let originalName: String
    let popularity: Double
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case castID = "cast_id"
        case character
        case creditID = "credit_id"
        case gender
        case knownForDepartment = "known_for_department"
        case name
        case order
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.castID = try container.decodeIfPresent(Int.self, forKey: .castID)
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? ""
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

// MARK: - MovieCreditCrew

nonisolated struct MovieCreditCrew: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let gender: Int?
    let job: String
    let knownForDepartment: String
    let name: String
    let originalName: String
    let popularity: Double
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case department
        case gender
        case job
        case knownForDepartment = "known_for_department"
        case name
        case originalName = "original_name"
        case popularity
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? ""
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender)
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

// MARK: - MovieVideosResponse

nonisolated struct MovieVideosResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [MovieVideo]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([MovieVideo].self, forKey: .results) ?? []
    }
}

// MARK: - MovieVideo

nonisolated struct MovieVideo: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MovieImagesResponse

nonisolated struct MovieImagesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let backdrops: [MovieImage]
    let logos: [MovieImage]
    let posters: [MovieImage]

    enum CodingKeys: String, CodingKey {
        case id
        case backdrops
        case logos
        case posters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.backdrops = try container.decodeIfPresent([MovieImage].self, forKey: .backdrops) ?? []
        self.logos = try container.decodeIfPresent([MovieImage].self, forKey: .logos) ?? []
        self.posters = try container.decodeIfPresent([MovieImage].self, forKey: .posters) ?? []
    }
}

// MARK: - MovieImage

nonisolated struct MovieImage: Decodable, Sendable, Equatable {
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

// MARK: - MovieRecommendationsPage

nonisolated struct MovieRecommendationsPage: Decodable, Sendable, Equatable {
    let page: Int
    let results: [MovieRecommendation]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        self.results = try container.decodeIfPresent([MovieRecommendation].self, forKey: .results) ?? []
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? results.count
    }
}

// MARK: - MovieRecommendation

nonisolated struct MovieRecommendation: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let adult: Bool
    let backdropPath: String?
    let genreIDs: [Int]
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let releaseDate: String
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case adult
        case backdropPath = "backdrop_path"
        case genreIDs = "genre_ids"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview
        case popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case title
        case video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? "未命名"
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - MovieWatchProvidersResponse

nonisolated struct MovieWatchProvidersResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [String: MovieWatchProviderCountry]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([String: MovieWatchProviderCountry].self, forKey: .results) ?? [:]
    }
}

// MARK: - MovieWatchProviderCountry

nonisolated struct MovieWatchProviderCountry: Decodable, Sendable, Equatable {
    let link: String
    let flatrate: [MovieWatchProvider]
    let buy: [MovieWatchProvider]
    let rent: [MovieWatchProvider]
    let ads: [MovieWatchProvider]
    let free: [MovieWatchProvider]

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
        self.flatrate = try container.decodeIfPresent([MovieWatchProvider].self, forKey: .flatrate) ?? []
        self.buy = try container.decodeIfPresent([MovieWatchProvider].self, forKey: .buy) ?? []
        self.rent = try container.decodeIfPresent([MovieWatchProvider].self, forKey: .rent) ?? []
        self.ads = try container.decodeIfPresent([MovieWatchProvider].self, forKey: .ads) ?? []
        self.free = try container.decodeIfPresent([MovieWatchProvider].self, forKey: .free) ?? []
    }
}

// MARK: - MovieWatchProvider

nonisolated struct MovieWatchProvider: Decodable, Sendable, Equatable, Identifiable {
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
