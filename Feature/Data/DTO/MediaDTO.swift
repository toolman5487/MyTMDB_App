//
//  MediaDTO.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - GenreDTO

nonisolated struct GenreDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}

// MARK: - ProductionCompanyDTO

nonisolated struct ProductionCompanyDTO: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - ProductionCountryDTO

nonisolated struct ProductionCountryDTO: Decodable, Sendable, Equatable {
    let iso3166Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case iso3166Code = "iso_3166_1"
        case name
    }
}

// MARK: - SpokenLanguageDTO

nonisolated struct SpokenLanguageDTO: Decodable, Sendable, Equatable {
    let englishName: String
    let iso639Code: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case englishName = "english_name"
        case iso639Code = "iso_639_1"
        case name
    }
}

// MARK: - VideosDTO

nonisolated struct VideosDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [VideoDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(id: Int, results: [VideoDTO] = []) {
        self.id = id
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([VideoDTO].self, forKey: .results) ?? []
    }
}

// MARK: - VideoDTO

nonisolated struct VideoDTO: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MediaImagesDTO

nonisolated struct MediaImagesDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let backdrops: [MediaImageDTO]
    let logos: [MediaImageDTO]
    let posters: [MediaImageDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case backdrops
        case logos
        case posters
    }

    init(
        id: Int,
        backdrops: [MediaImageDTO] = [],
        logos: [MediaImageDTO] = [],
        posters: [MediaImageDTO] = []
    ) {
        self.id = id
        self.backdrops = backdrops
        self.logos = logos
        self.posters = posters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.backdrops = try container.decodeIfPresent([MediaImageDTO].self, forKey: .backdrops) ?? []
        self.logos = try container.decodeIfPresent([MediaImageDTO].self, forKey: .logos) ?? []
        self.posters = try container.decodeIfPresent([MediaImageDTO].self, forKey: .posters) ?? []
    }
}

// MARK: - MediaImageDTO

nonisolated struct MediaImageDTO: Decodable, Sendable, Equatable {
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

// MARK: - MediaSummaryPageDTO

nonisolated struct MediaSummaryPageDTO: Decodable, Sendable, Equatable {
    let page: Int
    let results: [MediaSummaryDTO]
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
        results: [MediaSummaryDTO] = [],
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
        self.results = try container.decodeIfPresent([MediaSummaryDTO].self, forKey: .results) ?? []
        self.totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        self.totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? results.count
    }
}

// MARK: - MediaSummaryDTO

nonisolated struct MediaSummaryDTO: Decodable, Sendable, Equatable, Identifiable {
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
        case firstAirDate = "first_air_date"
        case title
        case name
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
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
            ?? ""
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - WatchProvidersDTO

nonisolated struct WatchProvidersDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let results: [String: WatchProviderCountryDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(id: Int, results: [String: WatchProviderCountryDTO] = [:]) {
        self.id = id
        self.results = results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.results = try container.decodeIfPresent([String: WatchProviderCountryDTO].self, forKey: .results) ?? [:]
    }
}

// MARK: - WatchProviderCountryDTO

nonisolated struct WatchProviderCountryDTO: Decodable, Sendable, Equatable {
    let link: String
    let flatrate: [WatchProviderDTO]
    let buy: [WatchProviderDTO]
    let rent: [WatchProviderDTO]
    let ads: [WatchProviderDTO]
    let free: [WatchProviderDTO]

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
        self.flatrate = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .flatrate) ?? []
        self.buy = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .buy) ?? []
        self.rent = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .rent) ?? []
        self.ads = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .ads) ?? []
        self.free = try container.decodeIfPresent([WatchProviderDTO].self, forKey: .free) ?? []
    }
}

// MARK: - WatchProviderDTO

nonisolated struct WatchProviderDTO: Decodable, Sendable, Equatable, Identifiable {
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
