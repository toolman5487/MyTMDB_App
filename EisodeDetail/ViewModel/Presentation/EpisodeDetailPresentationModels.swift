//
//  EpisodeDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - EpisodeDetailItem

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

    init(detail: Episode) {
        self.id = detail.id
        self.title = BaseDisplayTextFormatter.text(detail.name, fallback: "未命名集數")
        self.overview = BaseDisplayTextFormatter.overview(detail.overview)
        self.airDateText = BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: detail.airDate)
        )
        self.episodeNumberText = BaseDisplayTextFormatter.episodeNumberText(detail.episodeNumber)
        self.seasonNumberText = BaseDisplayTextFormatter.seasonNumberText(detail.seasonNumber)
        self.runtimeText = BaseDisplayTextFormatter.runtime(detail.runtime)
        self.productionCodeText = BaseDisplayTextFormatter.nonEmptyText(detail.productionCode)
        self.scoreText = BaseDisplayTextFormatter.decimal(detail.voteAverage)
        self.voteCountText = BaseDisplayTextFormatter.countText(detail.voteCount, unit: "票")
        self.stillURL = detail.stillPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
    }
}

// MARK: - EpisodePersonItem

nonisolated struct EpisodePersonItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(cast: EpisodeCastMember) {
        self.id = cast.creditID
        self.personID = cast.id
        self.title = BaseDisplayTextFormatter.text(cast.name, fallback: "未命名")
        self.subtitle = BaseDisplayTextFormatter.nonEmptyText(cast.character)
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(crew: EpisodeCrewMember) {
        self.id = crew.creditID
        self.personID = crew.id
        self.title = BaseDisplayTextFormatter.text(crew.name, fallback: "未命名")
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: crew.job,
            department: crew.department
        )
        self.profileURL = crew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

// MARK: - EpisodeVideoItem

nonisolated struct EpisodeVideoItem: Sendable, Equatable, Identifiable {
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

        if video.isYouTube, video.isPlayable {
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

// MARK: - EpisodeImageItem

nonisolated struct EpisodeImageItem: Sendable, Equatable, Identifiable {
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

// MARK: - EpisodeExternalLinkItem

nonisolated struct EpisodeExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let url: URL
}

// MARK: - EpisodeAccountStateItem

nonisolated struct EpisodeAccountStateItem: Sendable, Equatable {
    let ratingText: String

    init(value: Double) {
        self.ratingText = BaseDisplayTextFormatter.decimal(value)
    }

    init(accountState: EpisodeAccountState) {
        switch accountState.rating {
        case .unrated:
            self.ratingText = BaseDisplayTextFormatter.unratedText

        case .rated(let value):
            self.ratingText = BaseDisplayTextFormatter.decimal(value)
        }
    }
}
