//
//  PersonDetailDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonDetailDTO

nonisolated struct PersonDetailDTO: Decodable, Sendable {
    let id: Int
    let adult: Bool
    let alsoKnownAs: [String]
    let biography: String?
    let birthday: String?
    let deathday: String?
    let gender: Int
    let homepage: String?
    let imdbID: String?
    let knownForDepartment: String?
    let name: String?
    let placeOfBirth: String?
    let popularity: Double
    let profilePath: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case adult
        case alsoKnownAs = "also_known_as"
        case biography
        case birthday
        case deathday
        case gender
        case homepage
        case imdbID = "imdb_id"
        case knownForDepartment = "known_for_department"
        case name
        case placeOfBirth = "place_of_birth"
        case popularity
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        self.alsoKnownAs = try container.decodeIfPresent([String].self, forKey: .alsoKnownAs) ?? []
        self.biography = try container.decodeIfPresent(String.self, forKey: .biography)
        self.birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        self.deathday = try container.decodeIfPresent(String.self, forKey: .deathday)
        self.gender = try container.decodeIfPresent(Int.self, forKey: .gender) ?? 0
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.imdbID = try container.decodeIfPresent(String.self, forKey: .imdbID)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
        self.popularity = try container.decodeIfPresent(Double.self, forKey: .popularity) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

// MARK: - Person Credits DTOs

nonisolated struct PersonCreditsDTO: Decodable, Sendable {
    let id: Int
    let cast: [PersonCreditCastDTO]
    let crew: [PersonCreditCrewDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([PersonCreditCastDTO].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([PersonCreditCrewDTO].self, forKey: .crew) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
    }
}

nonisolated struct PersonCreditCastDTO: Decodable, Sendable {
    let id: Int
    let adult: Bool?
    let backdropPath: String?
    let character: String?
    let creditID: String?
    let episodeCount: Int?
    let firstAirDate: String?
    let genreIDs: [Int]?
    let mediaType: String?
    let name: String?
    let originalLanguage: String?
    let originalName: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String?
    let title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case adult
        case backdropPath = "backdrop_path"
        case character
        case creditID = "credit_id"
        case episodeCount = "episode_count"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
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
}

nonisolated struct PersonCreditCrewDTO: Decodable, Sendable {
    let id: Int
    let adult: Bool?
    let backdropPath: String?
    let creditID: String?
    let department: String?
    let episodeCount: Int?
    let firstAirDate: String?
    let genreIDs: [Int]?
    let job: String?
    let mediaType: String?
    let name: String?
    let originalLanguage: String?
    let originalName: String?
    let originalTitle: String?
    let overview: String?
    let popularity: Double?
    let posterPath: String?
    let releaseDate: String?
    let title: String?
    let video: Bool?
    let voteAverage: Double?
    let voteCount: Int?

    private enum CodingKeys: String, CodingKey {
        case id
        case adult
        case backdropPath = "backdrop_path"
        case creditID = "credit_id"
        case department
        case episodeCount = "episode_count"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
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
}

// MARK: - Person Metadata DTOs

nonisolated struct PersonImagesDTO: Decodable, Sendable {
    let id: Int
    let profiles: [PersonProfileImageDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.profiles = try container.decodeIfPresent([PersonProfileImageDTO].self, forKey: .profiles) ?? []
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case profiles
    }
}

nonisolated struct PersonProfileImageDTO: Decodable, Sendable {
    let aspectRatio: Double?
    let filePath: String?
    let height: Int?
    let languageCode: String?
    let voteAverage: Double?
    let voteCount: Int?
    let width: Int?

    private enum CodingKeys: String, CodingKey {
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case height
        case languageCode = "iso_639_1"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case width
    }
}

nonisolated struct PersonExternalIDsDTO: Decodable, Sendable {
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

    private enum CodingKeys: String, CodingKey {
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
}
