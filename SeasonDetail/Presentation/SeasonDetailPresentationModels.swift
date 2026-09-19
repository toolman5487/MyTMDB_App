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

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return localization.string("season_detail.section.information", defaultValue: "Season Information")

        case .episodes:
            return localization.string("season_detail.section.episodes", defaultValue: "Episodes")

        case .videos:
            return localization.string("detail.section.videos", defaultValue: "Trailers and Videos")

        case .cast:
            return localization.string("detail.section.cast", defaultValue: "Cast")

        case .crew:
            return localization.string("detail.section.crew", defaultValue: "Crew")

        case .images:
            return localization.string("season_detail.section.images", defaultValue: "Images and Posters")

        case .watchProviders:
            return localization.string("detail.section.watch_providers", defaultValue: "Where to Watch")

        case .accountState:
            return localization.string("common.rating.my_rating", defaultValue: "My Rating")
        }
    }

    func contentListConfiguration(
        seriesID: Int,
        seasonNumber: Int,
        localization: AppInterfaceLocalization
    ) -> DetailContentListConfiguration? {
        guard case .episodes(let items) = self else { return nil }

        return DetailContentListConfiguration(
            title: title(localization: localization)
                ?? localization.string("season_detail.section.episodes", defaultValue: "Episodes"),
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
    let ratingText: String
    let posterURL: URL?

    init(detail: Season, localization: AppInterfaceLocalization) {
        self.id = detail.id
        self.title = BaseDisplayTextFormatter.text(
            detail.name,
            fallback: localization.string("common.fallback.untitled_season", defaultValue: "Untitled Season")
        )
        self.overview = BaseDisplayTextFormatter.overview(
            detail.overview,
            localization: localization
        )
        self.airDateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: detail.airDate),
            localization: localization
        )
        self.episodeCountText = BaseDisplayTextFormatter.countText(
            detail.episodes.count,
            unit: .episodes,
            localization: localization
        )
        self.seasonNumberText = BaseDisplayTextFormatter.seasonNumberText(
            detail.seasonNumber,
            localization: localization
        )
        self.scoreText = BaseDisplayTextFormatter.decimal(detail.voteAverage)
        self.ratingText = BaseDisplayTextFormatter.ratingText(
            scoreText,
            localization: localization
        ) as String
        self.posterURL = detail.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
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

    init(episode: SeasonEpisode, localization: AppInterfaceLocalization) {
        self.id = episode.id
        self.episodeNumber = episode.episodeNumber
        self.title = BaseDisplayTextFormatter.episodeTitle(
            BaseDisplayTextFormatter.text(
                episode.name,
                fallback: localization.string("common.fallback.untitled_episode", defaultValue: "Untitled Episode")
            ),
            episodeNumber: episode.episodeNumber,
            localization: localization
        )
        self.subtitle = Self.makeSubtitle(episode: episode, localization: localization)
        self.overview = BaseDisplayTextFormatter.overview(
            episode.overview,
            localization: localization
        )
        self.stillURL = episode.stillPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
        }
        self.scoreText = BaseDisplayTextFormatter.decimal(episode.voteAverage)
    }

    private static func makeSubtitle(
        episode: SeasonEpisode,
        localization: AppInterfaceLocalization
    ) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.isoDayText(from: episode.airDate),
            BaseDisplayTextFormatter.runtime(episode.runtime, localization: localization)
        ]) ?? BaseDisplayTextFormatter.announcedText(nil, localization: localization)
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

    init(video: Video, localization: AppInterfaceLocalization) {
        self.id = video.id
        self.title = BaseDisplayTextFormatter.text(
            video.name,
            fallback: localization.string("common.fallback.untitled_video", defaultValue: "Untitled Video")
        )
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

    init(aggregateCast: AggregateCastMember, localization: AppInterfaceLocalization) {
        self.id = aggregateCast.id
        self.title = BaseDisplayTextFormatter.text(
            aggregateCast.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.subtitle = aggregateCast.characters.first
        self.profileURL = aggregateCast.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    init(creditCast: SeasonCreditCast, localization: AppInterfaceLocalization) {
        self.id = creditCast.id
        self.title = BaseDisplayTextFormatter.text(
            creditCast.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.subtitle = BaseDisplayTextFormatter.nonEmptyText(creditCast.character)
        self.profileURL = creditCast.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonCrewItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCrew: AggregateCrewMember, localization: AppInterfaceLocalization) {
        self.id = "\(aggregateCrew.id)-\(aggregateCrew.department)"
        self.personID = aggregateCrew.id
        self.title = BaseDisplayTextFormatter.text(
            aggregateCrew.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: aggregateCrew.jobs.first,
            department: aggregateCrew.department,
            localization: localization
        )
        self.profileURL = aggregateCrew.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    init(creditCrew: SeasonCreditCrew, localization: AppInterfaceLocalization) {
        self.id = creditCrew.creditID
        self.personID = creditCrew.id
        self.title = BaseDisplayTextFormatter.text(
            creditCrew.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: creditCrew.job,
            department: creditCrew.department,
            localization: localization
        )
        self.profileURL = creditCrew.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
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
        self.imageURL = TMDBResourceURL.image(path: image.filePath, size: .w500)
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
        link: String,
        localization: AppInterfaceLocalization
    ) {
        self.countryCode = countryCode
        self.providerID = provider.id
        self.title = BaseDisplayTextFormatter.text(
            provider.name,
            fallback: localization.string("common.fallback.unnamed_provider", defaultValue: "Unnamed Provider")
        )
        self.category = category
        self.linkURL = URL(string: link)
        self.logoURL = provider.logoPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonAccountStateItem: Sendable, Equatable {
    let ratingText: String

    init(
        accountState: SeasonAccountState,
        localization: AppInterfaceLocalization
    ) {
        switch accountState.rating {
        case .unrated:
            self.ratingText = BaseDisplayTextFormatter.unratedText(
                localization: localization
            )

        case .rated(let value):
            self.ratingText = BaseDisplayTextFormatter.decimal(value)
        }
    }
}
