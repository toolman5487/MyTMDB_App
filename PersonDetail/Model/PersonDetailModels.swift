//
//  PersonDetailModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import Foundation

// MARK: - PersonDetailContent

nonisolated struct PersonDetailContent: Sendable, Equatable {
    let detail: PersonDetail
    let combinedCredits: PersonCombinedCreditsResponse
    let images: PersonImagesResponse
    let externalIDs: PersonExternalIDs
}

// MARK: - PersonDetail

nonisolated struct PersonDetail: Decodable, Sendable, Equatable, Identifiable {
    let adult: Bool
    let alsoKnownAs: [String]
    let biography: String?
    let birthday: String?
    let deathday: String?
    let gender: PersonGender
    let homepage: String?
    let id: Int
    let imdbID: String?
    let knownForDepartment: String?
    let name: String
    let placeOfBirth: String?
    let popularity: Double
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case adult
        case alsoKnownAs = "also_known_as"
        case biography
        case birthday
        case deathday
        case gender
        case homepage
        case id
        case imdbID = "imdb_id"
        case knownForDepartment = "known_for_department"
        case name
        case placeOfBirth = "place_of_birth"
        case popularity
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.alsoKnownAs = try container.decodeIfPresent([String].self, forKey: .alsoKnownAs) ?? []
        self.biography = try container.decodeIfPresent(String.self, forKey: .biography)
        self.birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        self.deathday = try container.decodeIfPresent(String.self, forKey: .deathday)
        self.gender = try container.decodeIfPresent(PersonGender.self, forKey: .gender) ?? .notSpecified
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.id = try container.decode(Int.self, forKey: .id)
        self.imdbID = try container.decodeIfPresent(String.self, forKey: .imdbID)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

// MARK: - PersonGender

nonisolated enum PersonGender: Sendable, Equatable {
    case notSpecified
    case female
    case male
    case nonBinary
    case unknown(Int)
}

extension PersonGender: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)

        switch rawValue {
        case 0:
            self = .notSpecified

        case 1:
            self = .female

        case 2:
            self = .male

        case 3:
            self = .nonBinary

        default:
            self = .unknown(rawValue)
        }
    }
}

// MARK: - PersonCombinedCreditsResponse

nonisolated struct PersonCombinedCreditsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [PersonCombinedCreditCast]
    let crew: [PersonCombinedCreditCrew]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }

    init(
        id: Int,
        cast: [PersonCombinedCreditCast] = [],
        crew: [PersonCombinedCreditCrew] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([PersonCombinedCreditCast].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([PersonCombinedCreditCrew].self, forKey: .crew) ?? []
    }
}

// MARK: - PersonCreditMediaType

nonisolated enum PersonCreditMediaType: Sendable, Equatable {
    case movie
    case tv
    case unknown(String)
}

extension PersonCreditMediaType: Decodable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        switch rawValue {
        case "movie":
            self = .movie

        case "tv":
            self = .tv

        default:
            self = .unknown(rawValue)
        }
    }
}

// MARK: - PersonCombinedCreditCast

nonisolated struct PersonCombinedCreditCast: Decodable, Sendable, Equatable, Identifiable {
    let adult: Bool
    let backdropPath: String?
    let character: String
    let creditID: String
    let episodeCount: Int?
    let genreIDs: [Int]
    let id: Int
    let mediaType: PersonCreditMediaType
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let primaryDate: String?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case character
        case creditID = "credit_id"
        case episodeCount = "episode_count"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case id
        case mediaType = "media_type"
        case name
        case originalLanguage = "original_language"
        case originalName = "original_name"
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

        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount)
        self.genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        self.id = try container.decode(Int.self, forKey: .id)
        self.mediaType = try container.decodeIfPresent(PersonCreditMediaType.self, forKey: .mediaType) ?? .unknown("")
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle)
            ?? container.decodeIfPresent(String.self, forKey: .originalName)
            ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.primaryDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - PersonCombinedCreditCrew

nonisolated struct PersonCombinedCreditCrew: Decodable, Sendable, Equatable, Identifiable {
    let adult: Bool
    let backdropPath: String?
    let creditID: String
    let department: String
    let episodeCount: Int?
    let genreIDs: [Int]
    let id: Int
    let job: String
    let mediaType: PersonCreditMediaType
    let originalLanguage: String
    let originalTitle: String
    let overview: String
    let popularity: Double
    let posterPath: String?
    let primaryDate: String?
    let title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case adult
        case backdropPath = "backdrop_path"
        case creditID = "credit_id"
        case department
        case episodeCount = "episode_count"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case id
        case job
        case mediaType = "media_type"
        case name
        case originalLanguage = "original_language"
        case originalName = "original_name"
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

        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? ""
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.episodeCount = try container.decodeIfPresent(Int.self, forKey: .episodeCount)
        self.genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        self.id = try container.decode(Int.self, forKey: .id)
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.mediaType = try container.decodeIfPresent(PersonCreditMediaType.self, forKey: .mediaType) ?? .unknown("")
        self.originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage) ?? ""
        self.originalTitle = try container.decodeIfPresent(String.self, forKey: .originalTitle)
            ?? container.decodeIfPresent(String.self, forKey: .originalName)
            ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.primaryDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            ?? container.decodeIfPresent(String.self, forKey: .firstAirDate)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
            ?? container.decodeIfPresent(String.self, forKey: .name)
            ?? "未命名"
        self.video = try container.decodeIfPresent(Bool.self, forKey: .video) ?? false
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - PersonImagesResponse

nonisolated struct PersonImagesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let profiles: [PersonProfileImage]

    enum CodingKeys: String, CodingKey {
        case id
        case profiles
    }

    init(id: Int, profiles: [PersonProfileImage] = []) {
        self.id = id
        self.profiles = profiles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.profiles = try container.decodeIfPresent([PersonProfileImage].self, forKey: .profiles) ?? []
    }
}

// MARK: - PersonProfileImage

nonisolated struct PersonProfileImage: Decodable, Sendable, Equatable {
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

// MARK: - PersonExternalIDs

nonisolated struct PersonExternalIDs: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let facebookID: String?
    let freebaseID: String?
    let freebaseMID: String?
    let imdbID: String?
    let instagramID: String?
    let tiktokID: String?
    let twitterID: String?
    let wikidataID: String?
    let youtubeID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case facebookID = "facebook_id"
        case freebaseID = "freebase_id"
        case freebaseMID = "freebase_mid"
        case imdbID = "imdb_id"
        case instagramID = "instagram_id"
        case tiktokID = "tiktok_id"
        case twitterID = "twitter_id"
        case wikidataID = "wikidata_id"
        case youtubeID = "youtube_id"
    }

    init(
        id: Int,
        facebookID: String? = nil,
        freebaseID: String? = nil,
        freebaseMID: String? = nil,
        imdbID: String? = nil,
        instagramID: String? = nil,
        tiktokID: String? = nil,
        twitterID: String? = nil,
        wikidataID: String? = nil,
        youtubeID: String? = nil
    ) {
        self.id = id
        self.facebookID = facebookID
        self.freebaseID = freebaseID
        self.freebaseMID = freebaseMID
        self.imdbID = imdbID
        self.instagramID = instagramID
        self.tiktokID = tiktokID
        self.twitterID = twitterID
        self.wikidataID = wikidataID
        self.youtubeID = youtubeID
    }
}
