//
//  MovieDetailDTO.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - MovieDetailDTO

nonisolated struct MovieDetailDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String
    let overview: String?
    let adult: Bool
    let video: Bool
    let backdropPath: String?
    let posterPath: String?
    let belongsToCollection: MovieCollectionRefDTO?
    let budget: Int
    let genres: [GenreDTO]
    let homepage: String?
    let imdbID: String?
    let originalLanguage: String
    let originCountry: [String]
    let popularity: Double
    let productionCompanies: [ProductionCompanyDTO]
    let productionCountries: [ProductionCountryDTO]
    let releaseDate: String
    let revenue: Int
    let runtime: Int?
    let spokenLanguages: [SpokenLanguageDTO]
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
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle) ?? title
        self.tagline = try container.decodeIfPresent(String.self, forKey: .tagline) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.belongsToCollection = try container.decodeIfPresent(MovieCollectionRefDTO.self, forKey: .belongsToCollection)
        self.budget = try container.decodeIfPresent(Int.self, forKey: .budget) ?? 0
        self.genres = try container.decodeIfPresent([GenreDTO].self, forKey: .genres) ?? []
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.imdbID = try container.decodeIfPresent(String.self, forKey: .imdbID)
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originCountry = try container.decodeIfPresent([String].self, forKey: .originCountry) ?? []
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.productionCompanies = try container.decodeIfPresent(
            [ProductionCompanyDTO].self,
            forKey: .productionCompanies
        ) ?? []
        self.productionCountries = try container.decodeIfPresent(
            [ProductionCountryDTO].self,
            forKey: .productionCountries
        ) ?? []
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? ""
        self.revenue = try container.decodeIfPresent(Int.self, forKey: .revenue) ?? 0
        self.runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        self.spokenLanguages = try container.decodeIfPresent([SpokenLanguageDTO].self, forKey: .spokenLanguages) ?? []
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - MovieCollectionRefDTO

nonisolated struct MovieCollectionRefDTO: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - MovieCollectionDTO

nonisolated struct MovieCollectionDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let parts: [MovieCollectionPartDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case parts
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview)
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.parts = try container.decodeIfPresent([MovieCollectionPartDTO].self, forKey: .parts) ?? []
    }
}

// MARK: - MovieCollectionPartDTO

nonisolated struct MovieCollectionPartDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate) ?? ""
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - MovieCreditsDTO

nonisolated struct MovieCreditsDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [CastMemberDTO]
    let crew: [CrewMemberDTO]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(
        id: Int,
        cast: [CastMemberDTO] = [],
        crew: [CrewMemberDTO] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([CastMemberDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([CrewMemberDTO].self, forKey: .crew) ?? []
    }
}

// MARK: - CastMemberDTO

nonisolated struct CastMemberDTO: Decodable, Sendable, Equatable, Identifiable {
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
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

// MARK: - CrewMemberDTO

nonisolated struct CrewMemberDTO: Decodable, Sendable, Equatable, Identifiable {
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
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}
