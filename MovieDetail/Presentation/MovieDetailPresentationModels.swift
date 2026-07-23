//
//  MovieDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - MovieDetailSectionItem

nonisolated enum MovieDetailSectionItem: Sendable, Equatable {
    case overview(MovieDetailOverviewSectionItem)
    case facts([MovieDetailFactItem])
    case attributes(MovieDetailAttributeSectionItem)
    case cast([MovieDetailCastItem])
    case videos([MovieDetailVideoItem])
    case images([MovieDetailImageItem])
    case watchProviders([MovieWatchProviderItem])
    case recommendations([MovieDetailRecommendationItem])
    case similar([MovieDetailSimilarItem])

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "電影資訊"

        case .attributes:
            return "類型與製作公司"

        case .cast:
            return "主要演員"

        case .videos:
            return "預告與影片"

        case .images:
            return "劇照"

        case .watchProviders:
            return "觀看平台"

        case .recommendations:
            return "推薦電影"

        case .similar:
            return "相似電影"
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
                title: title ?? "推薦電影",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
                        destination: .movie(id: item.id)
                    )
                }
            )

        case .similar(let items):
            return DetailContentListConfiguration(
                title: title ?? "相似電影",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
                        destination: .movie(id: item.id)
                    )
                }
            )

        case .overview, .facts, .attributes, .watchProviders:
            return nil
        }
    }
}

// MARK: - MovieDetailOverviewSectionItem

nonisolated struct MovieDetailOverviewSectionItem: Sendable, Equatable {
    let hero: MovieDetailHeroItem
    let overview: String?
}

// MARK: - MovieDetailItem

nonisolated struct MovieDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let overview: String?
    let posterURL: URL?
    let backdropURL: URL?
    let releaseDateText: String?
    let runtimeText: String?
    let scoreText: String?
    let voteCountText: String?
    let statusText: String?
    let budgetText: String?
    let revenueText: String?
    let homepageURL: URL?
    let imdbURL: URL?

    init(detail: MovieDetail) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = BaseDisplayTextFormatter.nonEmptyText(detail.tagline)
        self.overview = BaseDisplayTextFormatter.nonEmptyText(detail.overview)
        self.posterURL = detail.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.backdropURL = detail.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.releaseDateText = BaseDisplayTextFormatter.nonEmptyText(detail.releaseDate)
        self.runtimeText = BaseDisplayTextFormatter.runtime(minutes: detail.runtime)
        self.scoreText = BaseDisplayTextFormatter.score(detail.voteAverage, voteCount: detail.voteCount)
        self.voteCountText = BaseDisplayTextFormatter.voteCount(detail.voteCount)
        self.statusText = BaseDisplayTextFormatter.nonEmptyText(detail.status)
        self.budgetText = BaseDisplayTextFormatter.currencyUSD(detail.budget)
        self.revenueText = BaseDisplayTextFormatter.currencyUSD(detail.revenue)
        self.homepageURL = Self.makeURL(from: detail.homepage)
        self.imdbURL = Self.makeIMDbURL(from: detail.imdbID)
    }

    private static func makeURL(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func makeIMDbURL(from imdbID: String?) -> URL? {
        guard let imdbID, !imdbID.isEmpty else { return nil }
        return URL(string: "https://www.imdb.com/title/\(imdbID)")
    }
}

// MARK: - MovieDetailHeroItem

nonisolated struct MovieDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let posterURL: URL?
    let backdropURL: URL?
    let scoreText: String?
    let voteCountText: String?
    let metadataText: String?

    init(detail: MovieDetailItem) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = detail.tagline
        self.posterURL = detail.posterURL
        self.backdropURL = detail.backdropURL
        self.scoreText = detail.scoreText
        self.voteCountText = detail.voteCountText
        self.metadataText = BaseDisplayTextFormatter.metadata([
            detail.releaseDateText,
            detail.runtimeText
        ])
    }
}

// MARK: - MovieDetailFactItem

nonisolated struct MovieDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

// MARK: - MovieDetailAttributeSectionItem

nonisolated struct MovieDetailAttributeSectionItem: Sendable, Equatable {
    let genres: [MovieDetailAttributeItem]
    let productionCompanies: [MovieDetailAttributeItem]

    var isEmpty: Bool {
        genres.isEmpty && productionCompanies.isEmpty
    }
}

// MARK: - MovieDetailAttributeItem

nonisolated struct MovieDetailAttributeItem: Sendable, Equatable, Identifiable {

    enum Kind: Sendable, Equatable {
        case genre
        case productionCompany
    }

    let id: String
    let sourceID: Int
    let title: String
    let kind: Kind

    init(genre: MovieDetailGenre) {
        self.id = "genre-\(genre.id)"
        self.sourceID = genre.id
        self.title = BaseFormatter.SimplifiedChineseTextMapper.traditionalChinese(from: genre.name)
        self.kind = .genre
    }

    init(productionCompany: MovieDetailProductionCompany) {
        self.id = "production-company-\(productionCompany.id)"
        self.sourceID = productionCompany.id
        self.title = productionCompany.name
        self.kind = .productionCompany
    }
}

// MARK: - MovieDetailCastItem

nonisolated struct MovieDetailCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let characterText: String
    let profileURL: URL?

    init(cast: MovieCreditCast) {
        self.id = cast.id
        self.name = cast.name
        self.characterText = BaseDisplayTextFormatter.nonEmptyText(cast.character) ?? ""
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

// MARK: - MovieDetailVideoItem

nonisolated struct MovieDetailVideoItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailURL: URL?
    let youtubeVideoKey: String?
    let videoURL: URL?

    init(video: MovieVideo) {
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

// MARK: - MovieDetailImageItem

nonisolated struct MovieDetailImageItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let resolutionText: String?
    let imageURL: URL

    init?(image: MovieImage, index: Int) {
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

// MARK: - MovieWatchProviderItem

nonisolated struct MovieWatchProviderItem: Sendable, Equatable, Identifiable {
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
        provider: MovieWatchProvider,
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

// MARK: - MovieDetailRecommendationItem

nonisolated struct MovieDetailRecommendationItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let releaseDateText: String
    let scoreText: String?
    let posterURL: URL?

    init(recommendation: MovieRecommendation) {
        self.id = recommendation.id
        self.title = recommendation.title
        self.releaseDateText = recommendation.releaseDate
        self.scoreText = BaseDisplayTextFormatter.score(
            recommendation.voteAverage,
            voteCount: recommendation.voteCount
        )
        self.posterURL = recommendation.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

// MARK: - MovieDetailSimilarItem

typealias MovieDetailSimilarItem = MovieDetailRecommendationItem
