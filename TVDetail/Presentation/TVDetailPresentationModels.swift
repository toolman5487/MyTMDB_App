//
//  TVDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - TVDetailSectionItem

nonisolated enum TVDetailSectionItem: Sendable, Equatable {
    case overview(TVDetailOverviewSectionItem)
    case facts([TVDetailFactItem])
    case videos([TVDetailVideoItem])
    case attributes(TVDetailAttributeSectionItem)
    case cast([TVDetailCastItem])
    case crew([TVDetailCrewItem])
    case seasons([TVDetailSeasonItem])
    case images([TVDetailImageItem])
    case recommendations([TVDetailRecommendationItem])
    case similar([TVDetailSimilarItem])
    case watchProviders([TVWatchProviderItem])

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "影集資訊"

        case .videos:
            return "預告與影片"

        case .attributes:
            return "類型、電視網與製作公司"

        case .cast:
            return "主要演員"

        case .crew:
            return "幕後人員"

        case .seasons:
            return "季數"

        case .images:
            return "劇照"

        case .recommendations:
            return "推薦影集"

        case .similar:
            return "相似影集"

        case .watchProviders:
            return "觀看平台"
        }
    }

    var contentListConfiguration: DetailContentListConfiguration? {
        switch self {
        case .cast(let items):
            return DetailContentListConfiguration(
                title: title ?? "主要演員",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.profileURL,
                        title: item.name,
                        subtitle: item.characterText,
                        destination: .person(id: item.id)
                    )
                }
            )

        case .crew(let items):
            return DetailContentListConfiguration(
                title: title ?? "幕後人員",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: item.id,
                        imageURL: item.profileURL,
                        title: item.name,
                        subtitle: BaseDisplayTextFormatter.metadata([
                            item.jobText,
                            item.episodeCountText
                        ]),
                        destination: .person(id: item.personID)
                    )
                }
            )

        case .videos(let items):
            return DetailContentListConfiguration(
                title: title ?? "預告與影片",
                thumbnailStyle: .landscape,
                items: items.map { item in
                    let destination: DetailContentListDestination
                    if let videoKey = item.youtubeVideoKey {
                        destination = .youtube(videoKey: videoKey, title: item.title)
                    } else if let videoURL = item.videoURL {
                        destination = .webVideo(url: videoURL, title: item.title)
                    } else {
                        destination = .none
                    }

                    return DetailContentListItem(
                        id: item.id,
                        imageURL: item.thumbnailURL,
                        title: item.title,
                        subtitle: item.subtitle,
                        destination: destination
                    )
                }
            )

        case .images(let items):
            return DetailContentListConfiguration(
                title: title ?? "劇照",
                thumbnailStyle: .gallery,
                items: items.map { item in
                    DetailContentListItem(
                        id: item.id,
                        imageURL: item.imageURL,
                        title: item.title,
                        subtitle: item.resolutionText,
                        destination: .image(url: item.imageURL)
                    )
                }
            )

        case .recommendations(let items):
            return DetailContentListConfiguration(
                title: title ?? "推薦影集",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
                        destination: .tv(seriesID: item.id)
                    )
                }
            )

        case .similar(let items):
            return DetailContentListConfiguration(
                title: title ?? "相似影集",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
                        destination: .tv(seriesID: item.id)
                    )
                }
            )

        case .overview, .facts, .attributes, .seasons, .watchProviders:
            return nil
        }
    }
}

// MARK: - TVDetailImageItem

nonisolated struct TVDetailImageItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let resolutionText: String?
    let imageURL: URL

    init?(image: MediaImage, index: Int) {
        guard let imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500) else {
            return nil
        }

        self.id = image.filePath
        self.title = "劇照 \(index + 1)"
        self.resolutionText = BaseDisplayTextFormatter.resolution(
            width: image.width,
            height: image.height
        )
        self.imageURL = imageURL
    }
}

// MARK: - TVDetailOverviewSectionItem

nonisolated struct TVDetailOverviewSectionItem: Sendable, Equatable {
    let hero: TVDetailHeroItem
    let overview: String?
}

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

    init(series: TVSeries) {
        self.id = series.id
        self.title = series.name
        self.originalTitle = series.originalName
        self.tagline = BaseDisplayTextFormatter.nonEmptyText(series.tagline)
        self.overview = BaseDisplayTextFormatter.nonEmptyText(series.overview)
        self.posterURL = series.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.backdropURL = series.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.firstAirDateText = BaseDisplayTextFormatter.isoDayText(from: series.firstAirDate)
        self.lastAirDateText = BaseDisplayTextFormatter.isoDayText(from: series.lastAirDate)
        self.episodeRunTimeText = BaseDisplayTextFormatter.firstRuntime(series.episodeRunTimes)
        self.seasonCountText = BaseDisplayTextFormatter.count(series.numberOfSeasons, unit: "季")
        self.episodeCountText = BaseDisplayTextFormatter.count(series.numberOfEpisodes, unit: "集")
        self.scoreText = BaseDisplayTextFormatter.decimal(series.voteAverage)
        self.voteCountText = BaseDisplayTextFormatter.voteCount(series.voteCount)
        self.statusText = BaseDisplayTextFormatter.nonEmptyText(series.status.rawText)
        self.typeText = BaseDisplayTextFormatter.nonEmptyText(series.type)
        self.homepageURL = series.homepage
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

    init(genre: Genre) {
        self.id = "genre-\(genre.id)"
        self.sourceID = genre.id
        self.title = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: genre.name)
        self.kind = .genre
    }

    init(productionCompany: ProductionCompany) {
        self.id = "production-company-\(productionCompany.id)"
        self.sourceID = productionCompany.id
        self.title = productionCompany.name
        self.kind = .productionCompany
    }

    init(network: Network) {
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

    init(cast: AggregateCastMember) {
        self.id = cast.id
        self.name = cast.name
        self.characterText = Self.makeCharacterText(characters: cast.characters)
        self.episodeCountText = BaseDisplayTextFormatter.count(cast.episodeCount, unit: "集") ?? ""
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeCharacterText(characters: [String]) -> String {
        let names = characters.compactMap(BaseDisplayTextFormatter.nonEmptyText)

        guard !names.isEmpty else { return "" }
        return Array(Set(names)).sorted().joined(separator: " / ")
    }
}

nonisolated struct TVDetailCrewItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let name: String
    let jobText: String
    let episodeCountText: String
    let profileURL: URL?

    init(crew: AggregateCrewMember) {
        self.id = "\(crew.id)-\(crew.department)"
        self.personID = crew.id
        self.name = crew.name
        self.jobText = Self.makeJobText(crew: crew)
        self.episodeCountText = BaseDisplayTextFormatter.count(crew.episodeCount, unit: "集") ?? ""
        self.profileURL = crew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeJobText(crew: AggregateCrewMember) -> String {
        let primaryJob = crew.jobs
            .first { BaseDisplayTextFormatter.nonEmptyText($0) != nil }

        return BaseFormatter.CrewJobDisplayMapper.displayText(
            job: primaryJob,
            department: crew.department
        ) ?? ""
    }
}

nonisolated struct TVDetailSeasonItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let seasonNumber: Int
    let posterURL: URL?

    init(season: TVSeason) {
        self.id = season.id
        self.title = season.name
        self.subtitle = Self.makeSubtitle(season: season)
        self.seasonNumber = season.seasonNumber
        self.posterURL = season.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeSubtitle(season: TVSeason) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.isoDayText(from: season.airDate),
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

    init(video: Video) {
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

nonisolated struct TVWatchProviderItem: Sendable, Equatable, Identifiable {
    var id: String {
        "\(countryCode)-\(category)-\(providerID)"
    }

    let countryCode: String
    let providerID: Int
    let title: String
    let category: String
    let linkURL: URL?
    let logoURL: URL?

    init(
        countryCode: String,
        provider: WatchProvider,
        category: String,
        link: String
    ) {
        self.countryCode = countryCode
        self.providerID = provider.id
        self.title = provider.name
        self.category = category
        self.linkURL = URL(string: link)
        self.logoURL = provider.logoPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct TVDetailRecommendationItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let firstAirDateText: String
    let scoreText: String?
    let posterURL: URL?

    init(recommendation: MediaSummary) {
        self.id = recommendation.id
        self.title = recommendation.title
        self.firstAirDateText = BaseDisplayTextFormatter.isoDayText(from: recommendation.releaseDate) ?? ""
        self.scoreText = BaseDisplayTextFormatter.score(
            recommendation.voteAverage,
            voteCount: recommendation.voteCount
        )
        self.posterURL = recommendation.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

// MARK: - TVDetailSimilarItem

typealias TVDetailSimilarItem = TVDetailRecommendationItem
