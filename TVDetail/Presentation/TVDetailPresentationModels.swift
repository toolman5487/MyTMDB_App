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
    case seasons([TVDetailSeasonItem])
    case images([TVDetailImageItem])
    case recommendations([TVDetailRecommendationItem])

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "影集資訊"

        case .videos:
            return "預告與影片"

        case .attributes:
            return "類型與製作公司"

        case .cast:
            return "主要演員"

        case .seasons:
            return "季數"

        case .images:
            return "劇照"

        case .recommendations:
            return "推薦影集"
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

        case .overview, .facts, .attributes, .seasons:
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

    init?(image: TVImage, index: Int) {
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
