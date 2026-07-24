//
//  SeasonDetailModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - SeasonDetailContent

nonisolated struct SeasonDetailContent: Sendable, Equatable {
    let detail: SeasonDetail
    let aggregateCredits: TVAggregateCreditsResponse
    let credits: SeasonCreditsResponse
    let images: TVImagesResponse
    let videos: TVVideosResponse
    let watchProviders: TVWatchProvidersResponse
    let externalIDs: SeasonExternalIDsResponse
    let translations: SeasonTranslationsResponse
    let accountStates: SeasonAccountStatesResponse
}

// MARK: - SeasonDetail

nonisolated struct SeasonDetail: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let tmdbInternalID: String
    let name: String
    let overview: String
    let airDate: String
    let episodes: [SeasonEpisode]
    let posterPath: String?
    let seasonNumber: Int
    let voteAverage: Double

    enum CodingKeys: String, CodingKey {
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
        self.tmdbInternalID = try container.decodeIfPresent(String.self, forKey: .tmdbInternalID) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名季數"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.episodes = try container.decodeIfPresent([SeasonEpisode].self, forKey: .episodes) ?? []
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
    }
}

// MARK: - SeasonEpisode

nonisolated struct SeasonEpisode: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let overview: String
    let airDate: String
    let episodeNumber: Int
    let episodeType: String
    let productionCode: String
    let runtime: Int?
    let seasonNumber: Int
    let showID: Int
    let stillPath: String?
    let voteAverage: Double
    let voteCount: Int
    let crew: [SeasonEpisodeCrewMember]
    let guestStars: [SeasonEpisodeGuestStar]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case overview
        case airDate = "air_date"
        case episodeNumber = "episode_number"
        case episodeType = "episode_type"
        case productionCode = "production_code"
        case runtime
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
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名集數"
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.airDate = try container.decodeIfPresent(String.self, forKey: .airDate) ?? ""
        self.episodeNumber = try container.decodeIfPresent(Int.self, forKey: .episodeNumber) ?? 0
        self.episodeType = try container.decodeIfPresent(String.self, forKey: .episodeType) ?? ""
        self.productionCode = try container.decodeIfPresent(String.self, forKey: .productionCode) ?? ""
        self.runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        self.seasonNumber = try container.decodeIfPresent(Int.self, forKey: .seasonNumber) ?? 0
        self.showID = try container.decodeIfPresent(Int.self, forKey: .showID) ?? 0
        self.stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage) ?? 0
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        self.crew = try container.decodeIfPresent([SeasonEpisodeCrewMember].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([SeasonEpisodeGuestStar].self, forKey: .guestStars) ?? []
    }
}

// MARK: - Episode People

nonisolated struct SeasonEpisodeCrewMember: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let creditID: String
    let department: String
    let job: String
    let name: String
    let originalName: String
    let profilePath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case creditID = "credit_id"
        case department
        case job
        case name
        case originalName = "original_name"
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.creditID = try container.decodeIfPresent(String.self, forKey: .creditID) ?? UUID().uuidString
        self.department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        self.job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originalName = try container.decodeIfPresent(String.self, forKey: .originalName) ?? name
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}

nonisolated struct SeasonEpisodeGuestStar: Decodable, Sendable, Equatable, Identifiable {
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

// MARK: - Season Credits

nonisolated struct SeasonCreditsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let cast: [SeasonCreditCast]
    let crew: [SeasonCreditCrew]
    let guestStars: [SeasonCreditGuestStar]

    enum CodingKeys: String, CodingKey {
        case id
        case cast
        case crew
        case guestStars = "guest_stars"
    }

    init(
        id: Int,
        cast: [SeasonCreditCast] = [],
        crew: [SeasonCreditCrew] = [],
        guestStars: [SeasonCreditGuestStar] = []
    ) {
        self.id = id
        self.cast = cast
        self.crew = crew
        self.guestStars = guestStars
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.cast = try container.decodeIfPresent([SeasonCreditCast].self, forKey: .cast) ?? []
        self.crew = try container.decodeIfPresent([SeasonCreditCrew].self, forKey: .crew) ?? []
        self.guestStars = try container.decodeIfPresent([SeasonCreditGuestStar].self, forKey: .guestStars) ?? []
    }
}

nonisolated struct SeasonCreditCast: Decodable, Sendable, Equatable, Identifiable {
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

nonisolated struct SeasonCreditCrew: Decodable, Sendable, Equatable, Identifiable {
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

typealias SeasonCreditGuestStar = SeasonCreditCast

// MARK: - External IDs

nonisolated struct SeasonExternalIDsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let freebaseMID: String?
    let freebaseID: String?
    let tvdbID: Int?
    let tvrageID: Int?
    let wikidataID: String?

    enum CodingKeys: String, CodingKey {
        case id
        case freebaseMID = "freebase_mid"
        case freebaseID = "freebase_id"
        case tvdbID = "tvdb_id"
        case tvrageID = "tvrage_id"
        case wikidataID = "wikidata_id"
    }

    init(
        id: Int,
        freebaseMID: String? = nil,
        freebaseID: String? = nil,
        tvdbID: Int? = nil,
        tvrageID: Int? = nil,
        wikidataID: String? = nil
    ) {
        self.id = id
        self.freebaseMID = freebaseMID
        self.freebaseID = freebaseID
        self.tvdbID = tvdbID
        self.tvrageID = tvrageID
        self.wikidataID = wikidataID
    }
}

// MARK: - Translations

nonisolated struct SeasonTranslationsResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let translations: [SeasonTranslation]

    init(id: Int, translations: [SeasonTranslation] = []) {
        self.id = id
        self.translations = translations
    }
}

nonisolated struct SeasonTranslation: Decodable, Sendable, Equatable, Identifiable {
    var id: String {
        "\(iso639Code)-\(iso31661Code)-\(name)"
    }

    let iso31661Code: String
    let iso639Code: String
    let name: String
    let englishName: String
    let data: SeasonTranslationData

    enum CodingKeys: String, CodingKey {
        case iso31661Code = "iso_3166_1"
        case iso639Code = "iso_639_1"
        case name
        case englishName = "english_name"
        case data
    }
}

nonisolated struct SeasonTranslationData: Decodable, Sendable, Equatable {
    let name: String
    let overview: String
    let homepage: String?

    enum CodingKeys: String, CodingKey {
        case name
        case overview
        case homepage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
    }
}

// MARK: - Account States

nonisolated struct SeasonAccountStatesResponse: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let rated: SeasonRatedState

    enum CodingKeys: String, CodingKey {
        case id
        case rated
    }

    init(
        id: Int,
        rated: SeasonRatedState = .unrated
    ) {
        self.id = id
        self.rated = rated
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decode(Int.self, forKey: .id)
        self.rated = try container.decodeIfPresent(SeasonRatedState.self, forKey: .rated) ?? .unrated
    }
}

nonisolated enum SeasonRatedState: Sendable, Equatable, Decodable {
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
        self = value.map(SeasonRatedState.rated) ?? .unrated
    }
}

// MARK: - Presentation Items

nonisolated struct SeasonDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let airDateText: String
    let episodeCountText: String
    let seasonNumberText: String
    let scoreText: String
    let posterURL: URL?

    init(detail: SeasonDetail) {
        self.id = detail.id
        self.title = detail.name
        self.overview = BaseDisplayTextFormatter.overview(detail.overview)
        self.airDateText = BaseDisplayTextFormatter.announcedText(detail.airDate)
        self.episodeCountText = BaseDisplayTextFormatter.countText(detail.episodes.count, unit: "集")
        self.seasonNumberText = BaseDisplayTextFormatter.seasonNumberText(detail.seasonNumber)
        self.scoreText = BaseDisplayTextFormatter.decimal(detail.voteAverage)
        self.posterURL = detail.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
    }
}

nonisolated struct SeasonEpisodeItem: Sendable, Equatable, Identifiable {
    let id: Int
    let episodeNumber: Int
    let title: String
    let subtitle: String
    let overview: String
    let stillURL: URL?
    let scoreText: String

    init(episode: SeasonEpisode) {
        self.id = episode.id
        self.episodeNumber = episode.episodeNumber
        self.title = BaseDisplayTextFormatter.episodeTitle(
            episode.name,
            episodeNumber: episode.episodeNumber
        )
        self.subtitle = Self.makeSubtitle(episode: episode)
        self.overview = BaseDisplayTextFormatter.overview(episode.overview)
        self.stillURL = episode.stillPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.scoreText = BaseDisplayTextFormatter.decimal(episode.voteAverage)
    }

    private static func makeSubtitle(episode: SeasonEpisode) -> String {
        BaseDisplayTextFormatter.metadata([
            episode.airDate,
            BaseDisplayTextFormatter.minutes(episode.runtime)
        ]) ?? BaseDisplayTextFormatter.announcedText(nil)
    }
}

nonisolated struct SeasonDetailFactItem: Sendable, Equatable, Identifiable {
    var id: String {
        title
    }

    let title: String
    let value: String
}
