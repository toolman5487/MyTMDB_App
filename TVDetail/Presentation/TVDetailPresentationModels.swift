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

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return localization.string("tv_detail.section.information", defaultValue: "TV Show Information")

        case .videos:
            return localization.string("detail.section.videos", defaultValue: "Trailers and Videos")

        case .attributes:
            return localization.string("tv_detail.section.attributes", defaultValue: "Genres, Networks, and Production Companies")

        case .cast:
            return localization.string("detail.section.cast", defaultValue: "Cast")

        case .crew:
            return localization.string("detail.section.crew", defaultValue: "Crew")

        case .seasons:
            return localization.string("tv_detail.section.seasons", defaultValue: "Seasons")

        case .images:
            return localization.string("detail.section.images", defaultValue: "Images")

        case .recommendations:
            return localization.string("tv_detail.section.recommendations", defaultValue: "Recommended TV Shows")

        case .similar:
            return localization.string("tv_detail.section.similar", defaultValue: "Similar TV Shows")

        case .watchProviders:
            return localization.string("detail.section.watch_providers", defaultValue: "Where to Watch")
        }
    }

    func contentListConfiguration(
        localization: AppInterfaceLocalization
    ) -> DetailContentListConfiguration? {
        switch self {
        case .cast(let items):
            return DetailContentListConfiguration(
                title: title(localization: localization) ?? localization.string("detail.section.cast", defaultValue: "Cast"),
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
                title: title(localization: localization) ?? localization.string("detail.section.crew", defaultValue: "Crew"),
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
                title: title(localization: localization) ?? localization.string("detail.section.videos", defaultValue: "Trailers and Videos"),
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
                title: title(localization: localization) ?? localization.string("detail.section.images", defaultValue: "Images"),
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
                title: title(localization: localization) ?? localization.string("tv_detail.section.recommendations", defaultValue: "Recommended TV Shows"),
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(
                            item.scoreText,
                            localization: localization
                        ),
                        destination: .tv(seriesID: item.id)
                    )
                }
            )

        case .similar(let items):
            return DetailContentListConfiguration(
                title: title(localization: localization) ?? localization.string("tv_detail.section.similar", defaultValue: "Similar TV Shows"),
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(
                            item.scoreText,
                            localization: localization
                        ),
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

    init?(
        image: MediaImage,
        index: Int,
        localization: AppInterfaceLocalization
    ) {
        guard let imageURL = TMDBResourceURL.image(path: image.filePath, size: .w500) else {
            return nil
        }

        self.id = image.filePath
        self.title = localization.formatted(
            "detail.image.title_format",
            defaultValue: "Image %lld",
            index + 1
        )
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

    init(series: TVSeries, localization: AppInterfaceLocalization) {
        self.id = series.id
        self.title = BaseDisplayTextFormatter.text(
            series.name,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.originalTitle = series.originalName
        self.tagline = BaseDisplayTextFormatter.nonEmptyText(series.tagline)
        self.overview = BaseDisplayTextFormatter.nonEmptyText(series.overview)
        self.posterURL = series.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
        }
        self.backdropURL = series.backdropPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
        }
        self.firstAirDateText = BaseDisplayTextFormatter.isoDayText(from: series.firstAirDate)
        self.lastAirDateText = BaseDisplayTextFormatter.isoDayText(from: series.lastAirDate)
        self.episodeRunTimeText = BaseDisplayTextFormatter.firstRuntime(
            series.episodeRunTimes,
            localization: localization
        )
        self.seasonCountText = BaseDisplayTextFormatter.count(
            series.numberOfSeasons,
            unit: .seasons,
            localization: localization
        )
        self.episodeCountText = BaseDisplayTextFormatter.count(
            series.numberOfEpisodes,
            unit: .episodes,
            localization: localization
        )
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
    let scoreDisplayText: String?
    let metadataText: String?

    init(detail: TVDetailItem, localization: AppInterfaceLocalization) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = detail.tagline
        self.posterURL = detail.posterURL
        self.backdropURL = detail.backdropURL
        self.scoreText = detail.scoreText
        self.voteCountText = detail.voteCountText
        self.scoreDisplayText = BaseDisplayTextFormatter.ratingText(
            scoreText: detail.scoreText,
            voteCountText: detail.voteCountText,
            localization: localization
        )
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

    init(cast: AggregateCastMember, localization: AppInterfaceLocalization) {
        self.id = cast.id
        self.name = BaseDisplayTextFormatter.text(
            cast.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.characterText = Self.makeCharacterText(characters: cast.characters)
        self.episodeCountText = BaseDisplayTextFormatter.count(
            cast.episodeCount,
            unit: .episodes,
            localization: localization
        ) ?? ""
        self.profileURL = cast.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
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

    init(crew: AggregateCrewMember, localization: AppInterfaceLocalization) {
        self.id = "\(crew.id)-\(crew.department)"
        self.personID = crew.id
        self.name = BaseDisplayTextFormatter.text(
            crew.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.jobText = Self.makeJobText(crew: crew, localization: localization)
        self.episodeCountText = BaseDisplayTextFormatter.count(
            crew.episodeCount,
            unit: .episodes,
            localization: localization
        ) ?? ""
        self.profileURL = crew.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    private static func makeJobText(
        crew: AggregateCrewMember,
        localization: AppInterfaceLocalization
    ) -> String {
        let primaryJob = crew.jobs
            .first { BaseDisplayTextFormatter.nonEmptyText($0) != nil }

        return BaseFormatter.CrewJobDisplayMapper.displayText(
            job: primaryJob,
            department: crew.department,
            localization: localization
        ) ?? ""
    }
}

nonisolated struct TVDetailSeasonItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String
    let seasonNumber: Int
    let posterURL: URL?

    init(season: TVSeason, localization: AppInterfaceLocalization) {
        self.id = season.id
        self.title = BaseDisplayTextFormatter.text(
            season.name,
            fallback: localization.string("common.fallback.untitled_season", defaultValue: "Untitled Season")
        )
        self.subtitle = Self.makeSubtitle(season: season, localization: localization)
        self.seasonNumber = season.seasonNumber
        self.posterURL = season.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    private static func makeSubtitle(
        season: TVSeason,
        localization: AppInterfaceLocalization
    ) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.isoDayText(from: season.airDate),
            BaseDisplayTextFormatter.count(
                season.episodeCount,
                unit: .episodes,
                localization: localization
            )
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

nonisolated struct TVDetailRecommendationItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let firstAirDateText: String
    let scoreText: String?
    let posterURL: URL?

    init(recommendation: MediaSummary, localization: AppInterfaceLocalization) {
        self.id = recommendation.id
        self.title = BaseDisplayTextFormatter.text(
            recommendation.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.firstAirDateText = BaseDisplayTextFormatter.isoDayText(from: recommendation.releaseDate) ?? ""
        self.scoreText = BaseDisplayTextFormatter.score(
            recommendation.voteAverage,
            voteCount: recommendation.voteCount
        )
        self.posterURL = recommendation.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }
}

// MARK: - TVDetailSimilarItem

typealias TVDetailSimilarItem = TVDetailRecommendationItem
