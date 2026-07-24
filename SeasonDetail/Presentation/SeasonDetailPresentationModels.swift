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

nonisolated struct SeasonVideoItem: Sendable, Equatable, Identifiable {
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

nonisolated struct SeasonCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCast: TVAggregateCreditCast) {
        self.id = aggregateCast.id
        self.title = aggregateCast.name
        self.subtitle = aggregateCast.roles.first?.character
        self.profileURL = aggregateCast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCast: SeasonCreditCast) {
        self.id = creditCast.id
        self.title = creditCast.name
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

    init(aggregateCrew: TVAggregateCreditCrew) {
        self.id = "\(aggregateCrew.id)-\(aggregateCrew.department)"
        self.personID = aggregateCrew.id
        self.title = aggregateCrew.name
        self.subtitle = aggregateCrew.jobs.first?.job ?? aggregateCrew.department
        self.profileURL = aggregateCrew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCrew: SeasonCreditCrew) {
        self.id = creditCrew.creditID
        self.personID = creditCrew.id
        self.title = creditCrew.name
        self.subtitle = creditCrew.job.isEmpty ? creditCrew.department : creditCrew.job
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

    init(image: TVImage) {
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
        provider: TVWatchProvider,
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

    init(accountStates: SeasonAccountStatesResponse) {
        switch accountStates.rated {
        case .unrated:
            self.ratingText = BaseDisplayTextFormatter.unratedText

        case .rated(let value):
            self.ratingText = BaseDisplayTextFormatter.decimal(value)
        }
    }
}
