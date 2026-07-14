//
//  EpisodeDetailModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation

// MARK: - EpisodeDetailContent

nonisolated struct EpisodeDetailContent: Sendable, Equatable {
    let detail: EpisodeDetail
    let credits: EpisodeCreditsResponse
    let images: EpisodeImagesResponse
    let videos: TVVideosResponse
    let externalIDs: EpisodeExternalIDsResponse
    let translations: EpisodeTranslationsResponse
    let accountStates: EpisodeAccountStatesResponse
}

// MARK: - EpisodeDetail

nonisolated struct EpisodeDetail: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: String
    let crew: [EpisodeCrewMember]
    let episodeNumber: Int
    let guestStars: [EpisodeGuestStar]
    let productionCode: String
    let runtime: Int?
    let seasonNumber: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case crew
        case episodeNumber = "episode_number"
        case guestStars = "guest_stars"
        case productionCode = "production_code"
        case runtime
        case seasonNumber = "season_number"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名集數"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.crew = try container.decodeIfPresent([EpisodeCrewMember].self, forKey: .crew) ?? []
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.guestStars = try container.decodeIfPresent([EpisodeGuestStar].self, forKey: .guestStars) ?? []
        self.productionCode = try container.decodeIfPresent(String.self, forKey: .productionCode) ?? ""
        self.runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
    }
}

// MARK: - Episode Credits

nonisolated struct EpisodeCreditsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [EpisodeCastMember]
    let crew: [EpisodeCrewMember]
    let guestStars: [EpisodeGuestStar]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
        case guestStars = "guest_stars"
    }

    init(
        id: Int,
        cast: [EpisodeCastMember] = [],
        crew: [EpisodeCrewMember] = [],
        guestStars: [EpisodeGuestStar] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
        self.guestStars = guestStars
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([EpisodeCastMember].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([EpisodeCrewMember].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([EpisodeGuestStar].self, forKey: .guestStars) ?? []
    }
}

nonisolated struct EpisodeCastMember: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let character: String
    let creditID: String
    let name: String
    let order: Int
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case character
        case creditID = "credit_id"
        case name
        case order
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? UUID().uuidString
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

nonisolated struct EpisodeCrewMember: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let job: String
    let name: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case department
        case job
        case name
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? UUID().uuidString
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

typealias EpisodeGuestStar = EpisodeCastMember

// MARK: - Episode Images

nonisolated struct EpisodeImagesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let stills: [TVImage]

    enum CodingKeys: String, CodingKey {
        case id
        case stills
    }

    init(id: Int, stills: [TVImage] = []) {
        self.id = id
        self.stills = stills
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.stills = try container.decodeIfPresent([TVImage].self, forKey: .stills) ?? []
    }
}

// MARK: - External IDs

nonisolated struct EpisodeExternalIDsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let imdbID: String?
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case imdbID = "imdb_id"
        case freebaseMID = "freebase_mid"
        case freebaseID = "freebase_id"
        case tvdbID = "tvdb_id"
        case tvrageID = "tvrage_id"
        case wikidataID = "wikidata_id"
    }

    init(
        id: Int,
        imdbID: String? = nil,
        freebaseMID: String? = nil,
        freebaseID: String? = nil,
        tvdbID: Int? = nil,
        tvrageID: Int? = nil,
        wikidataID: String? = nil
    ) {
        self.id = id
        self.imdbID = imdbID
        self.freebaseMID = freebaseMID
        self.freebaseID = freebaseID
        self.tvdbID = tvdbID
        self.tvrageID = tvrageID
        self.wikidataID = wikidataID
    }
}

// MARK: - Translations

nonisolated struct EpisodeTranslationsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let translations: [EpisodeTranslation]

    init(id: Int, translations: [EpisodeTranslation] = []) {
        self.id = id
        self.translations = translations
    }
}

nonisolated struct EpisodeTranslation: Decodable, Sendable, Equatable, Identifiable {
    var id: String {
        "\(iso639Code)-\(iso31661Code)-\(name)"
    }

    let iso31661Code: String
    let iso639Code: String
    let name: String
    let englishName: String
    let data: EpisodeTranslationData

    enum CodingKeys: String, CodingKey {
        case iso31661Code = "iso_3166_1"
        case iso639Code = "iso_639_1"
        case name
        case englishName = "english_name"
        case data
    }
}

nonisolated struct EpisodeTranslationData: Decodable, Sendable, Equatable {
    let name: String
    let overview: String

    enum CodingKeys: String, CodingKey {
        case name
        case overview
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
    }
}

// MARK: - Account States

nonisolated struct EpisodeAccountStatesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let rated: EpisodeRatedState

    enum CodingKeys: String, CodingKey {
        case id
        case rated
    }

    init(
        id: Int,
        rated: EpisodeRatedState = .unrated
    ) {
        self.id = id
        self.rated = rated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.rated = try container.decodeIfPresent(EpisodeRatedState.self, forKey: .rated) ?? .unrated
    }
}

nonisolated enum EpisodeRatedState: Sendable, Equatable, Decodable {
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
        self = value.map(EpisodeRatedState.rated) ?? .unrated
    }
}

// MARK: - Presentation Items

nonisolated struct EpisodeDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let airDateText: String
    let episodeNumberText: String
    let seasonNumberText: String
    let runtimeText: String?
    let productionCodeText: String?
    let scoreText: String
    let voteCountText: String
    let stillURL: URL?

    init(detail: EpisodeDetail) {
        self.id = detail.id
        self.title = detail.name
        self.overview = detail.overview.isEmpty ? "目前沒有簡介。" : detail.overview
        self.airDateText = detail.airDate.isEmpty ? "尚未公布" : detail.airDate
        self.episodeNumberText = "第 \(detail.episodeNumber) 集"
        self.seasonNumberText = "第 \(detail.seasonNumber) 季"
        self.runtimeText = detail.runtime.map { "\($0) 分鐘" }
        self.productionCodeText = detail.productionCode.isEmpty ? nil : detail.productionCode
        self.scoreText = String(format: "%.1f", detail.voteAverage)
        self.voteCountText = "\(detail.voteCount) 票"
        self.stillURL = detail.stillPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
    }
}

nonisolated struct EpisodePersonItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(cast: EpisodeCastMember) {
        self.id = cast.creditID
        self.personID = cast.id
        self.title = cast.name
        self.subtitle = cast.character.isEmpty ? nil : cast.character
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(crew: EpisodeCrewMember) {
        self.id = crew.creditID
        self.personID = crew.id
        self.title = crew.name
        self.subtitle = crew.job.isEmpty ? crew.department : crew.job
        self.profileURL = crew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct EpisodeVideoItem: Sendable, Equatable, Identifiable {
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

nonisolated struct EpisodeImageItem: Sendable, Equatable, Identifiable {
    var id: String {
        filePath
    }

    let filePath: String
    let imageURL: URL?
    let aspectRatio: Double

    init(image: TVImage) {
        self.filePath = image.filePath
        self.imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500)
        self.aspectRatio = image.aspectRatio
    }
}

nonisolated struct EpisodeExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let url: URL
}

nonisolated struct EpisodeAccountStateItem: Sendable, Equatable {
    let ratingText: String

    init(value: Double) {
        self.ratingText = String(format: "%.1f", value)
    }

    init(accountStates: EpisodeAccountStatesResponse) {
        switch accountStates.rated {
        case .unrated:
            self.ratingText = "尚未評分"

        case .rated(let value):
            self.ratingText = String(format: "%.1f", value)
        }
    }
}
