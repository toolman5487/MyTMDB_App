//
//  SeasonDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - SeasonDetailSectionItem

nonisolated enum SeasonDetailSectionItem: Sendable, Equatable {
    case overview(SeasonDetailOverviewSectionItem)
    case facts([SeasonDetailFactItem])
    case episodes([SeasonEpisodeItem])
    case videos([SeasonVideoItem])
    case cast([SeasonCastItem])
    case crew([SeasonCrewItem])
    case images(SeasonImageGalleryItem)
    case watchProviders([SeasonWatchProviderItem])
    case accountState(SeasonAccountStateItem)

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "季數資訊"

        case .episodes:
            return "劇集"

        case .videos:
            return "預告與影片"

        case .cast:
            return "主要演員"

        case .crew:
            return "幕後人員"

        case .images:
            return "劇照與海報"

        case .watchProviders:
            return "觀看平台"

        case .accountState:
            return "我的評分"
        }
    }

    func contentListConfiguration(
        seriesID: Int,
        seasonNumber: Int
    ) -> DetailContentListConfiguration? {
        guard case .episodes(let items) = self else { return nil }

        return DetailContentListConfiguration(
            title: title ?? "劇集",
            thumbnailStyle: .landscape,
            items: items.map { item in
                DetailContentListItem(
                    id: String(item.id),
                    imageURL: item.stillURL,
                    title: item.title,
                    subtitle: item.subtitle,
                    destination: .episode(
                        seriesID: seriesID,
                        seasonNumber: seasonNumber,
                        episodeNumber: item.episodeNumber
                    )
                )
            }
        )
    }
}

// MARK: - SeasonDetailOverviewSectionItem

nonisolated struct SeasonDetailOverviewSectionItem: Sendable, Equatable {
    let hero: SeasonDetailItem
    let overview: String?
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

    init(detail: Season) {
        self.id = detail.id
        self.title = BaseDisplayTextFormatter.text(detail.name, fallback: "未命名季數")
        self.overview = BaseDisplayTextFormatter.overview(detail.overview)
        self.airDateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: detail.airDate)
        )
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
            BaseDisplayTextFormatter.text(episode.name, fallback: "未命名集數"),
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
            BaseDisplayTextFormatter.isoDayText(from: episode.airDate),
            BaseDisplayTextFormatter.runtime(episode.runtime)
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

nonisolated struct SeasonVideoItem: Sendable, Equatable, Identifiable {
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

nonisolated struct SeasonCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCast: AggregateCastMember) {
        self.id = aggregateCast.id
        self.title = BaseDisplayTextFormatter.text(aggregateCast.name, fallback: "未命名")
        self.subtitle = aggregateCast.characters.first
        self.profileURL = aggregateCast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCast: SeasonCreditCast) {
        self.id = creditCast.id
        self.title = BaseDisplayTextFormatter.text(creditCast.name, fallback: "未命名")
        self.subtitle = BaseDisplayTextFormatter.nonEmptyText(creditCast.character)
        self.profileURL = creditCast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonCrewItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCrew: AggregateCrewMember) {
        self.id = "\(aggregateCrew.id)-\(aggregateCrew.department)"
        self.personID = aggregateCrew.id
        self.title = BaseDisplayTextFormatter.text(aggregateCrew.name, fallback: "未命名")
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: aggregateCrew.jobs.first,
            department: aggregateCrew.department
        )
        self.profileURL = aggregateCrew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCrew: SeasonCreditCrew) {
        self.id = creditCrew.creditID
        self.personID = creditCrew.id
        self.title = BaseDisplayTextFormatter.text(creditCrew.name, fallback: "未命名")
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: creditCrew.job,
            department: creditCrew.department
        )
        self.profileURL = creditCrew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonImageGalleryItem: Sendable, Equatable {
    let posters: [SeasonImageItem]
    let backdrops: [SeasonImageItem]
    let logos: [SeasonImageItem]

    var isEmpty: Bool {
        posters.isEmpty && backdrops.isEmpty && logos.isEmpty
    }
}

nonisolated struct SeasonImageItem: Sendable, Equatable, Identifiable {
    var id: String {
        filePath
    }

    let filePath: String
    let imageURL: URL?
    let aspectRatio: Double

    init(image: MediaImage) {
        self.filePath = image.filePath
        self.imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500)
        self.aspectRatio = image.aspectRatio
    }
}

nonisolated struct SeasonWatchProviderItem: Sendable, Equatable, Identifiable {
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

nonisolated struct SeasonAccountStateItem: Sendable, Equatable {
    let ratingText: String

    init(accountState: SeasonAccountState) {
        switch accountState.rating {
        case .unrated:
            self.ratingText = BaseDisplayTextFormatter.unratedText

        case .rated(let value):
            self.ratingText = BaseDisplayTextFormatter.decimal(value)
        }
    }
}
