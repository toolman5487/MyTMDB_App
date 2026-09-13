//
//  MemberCenterListPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterListViewState

nonisolated enum MemberCenterListViewState: Equatable {
    case idle
    case loading
    case loaded(MemberCenterListContent)
    case empty(MemberCenterDestination)
    case failed(ErrorMessage)
}

// MARK: - MemberCenterListContent

nonisolated struct MemberCenterListContent: Sendable, Equatable {
    let destination: MemberCenterDestination
    let items: [MemberCenterListItem]
    let currentPage: Int
    let totalPages: Int
    let totalResults: Int
    let isLoadingNextPage: Bool

    var canLoadNextPage: Bool {
        currentPage < totalPages
    }

    func updatingLoadingNextPage(_ isLoading: Bool) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: destination,
            items: items,
            currentPage: currentPage,
            totalPages: totalPages,
            totalResults: totalResults,
            isLoadingNextPage: isLoading
        )
    }

    func appending(_ nextContent: MemberCenterListContent) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: nextContent.destination,
            items: items + nextContent.items,
            currentPage: nextContent.currentPage,
            totalPages: nextContent.totalPages,
            totalResults: nextContent.totalResults,
            isLoadingNextPage: false
        )
    }
}

// MARK: - MemberCenterListItemDetailTarget

nonisolated enum MemberCenterListItemDetailTarget: Sendable, Equatable {
    case movie(id: Int)
    case tv(id: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
    case list(id: Int)
}

// MARK: - MemberCenterListItem

nonisolated struct MemberCenterListItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let metadataText: String
    let imageURL: URL?
    let detailTarget: MemberCenterListItemDetailTarget

    init(item: AccountCollectionItem, destination: MemberCenterDestination) {
        switch item {
        case .media(let summary, let kind):
            self.id = Self.identifier(destination: destination, kind: kind, mediaID: summary.id)
            self.title = summary.title
            self.subtitle = Self.dateText(summary.releaseDate)
            self.metadataText = BaseDisplayTextFormatter.ratingText(summary.voteAverage)
            self.imageURL = Self.posterURL(path: summary.posterPath)
            self.detailTarget = Self.detailTarget(kind: kind, mediaID: summary.id)

        case .ratedMedia(let ratedMedia):
            self.id = Self.identifier(
                destination: destination,
                kind: ratedMedia.kind,
                mediaID: ratedMedia.summary.id
            )
            self.title = ratedMedia.summary.title
            self.subtitle = Self.dateText(ratedMedia.summary.releaseDate)
            self.metadataText = BaseDisplayTextFormatter.userRatingText(ratedMedia.rating)
            self.imageURL = Self.posterURL(path: ratedMedia.summary.posterPath)
            self.detailTarget = Self.detailTarget(
                kind: ratedMedia.kind,
                mediaID: ratedMedia.summary.id
            )

        case .ratedEpisode(let episode):
            self.id = "\(destination.rawValue)-episode-\(episode.seriesID)-\(episode.seasonNumber)-\(episode.episodeNumber)-\(episode.id)"
            self.title = episode.name
            self.subtitle = Self.episodeSubtitle(episode)
            self.metadataText = BaseDisplayTextFormatter.userRatingText(episode.rating)
            self.imageURL = Self.posterURL(path: episode.stillPath)
            self.detailTarget = .episode(
                seriesID: episode.seriesID,
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber
            )

        case .list(let list):
            self.id = "\(destination.rawValue)-list-\(list.id)"
            self.title = list.name
            self.subtitle = list.description.isEmpty ? "沒有描述" : list.description
            self.metadataText = BaseDisplayTextFormatter.countText(list.itemCount, unit: "個項目")
            self.imageURL = Self.posterURL(path: list.posterPath)
            self.detailTarget = .list(id: list.id)
        }
    }

    // MARK: - Private Methods

    private static func identifier(
        destination: MemberCenterDestination,
        kind: MediaKind,
        mediaID: Int
    ) -> String {
        "\(destination.rawValue)-\(kind.rawValue)-\(mediaID)"
    }

    private static func detailTarget(
        kind: MediaKind,
        mediaID: Int
    ) -> MemberCenterListItemDetailTarget {
        switch kind {
        case .movie:
            return .movie(id: mediaID)

        case .tv:
            return .tv(id: mediaID)
        }
    }

    private static func dateText(_ day: CalendarDay?) -> String {
        BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: day)
        )
    }

    private static func posterURL(path: String?) -> URL? {
        path.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func episodeSubtitle(_ episode: RatedEpisode) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.seasonEpisodeNumberText(
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber
            ),
            BaseDisplayTextFormatter.isoDayText(from: episode.airDate)
        ]) ?? ""
    }
}

// MARK: - Accessibility

extension MemberCenterListItem {

    var accessibilityText: AccessibilityText {
        AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                subtitle,
                metadataText
            ]),
            hint: accessibilityHint
        )
    }

    private var accessibilityHint: String {
        switch detailTarget {
        case .movie:
            return "點兩下開啟電影詳細資料"

        case .tv:
            return "點兩下開啟劇集詳細資料"

        case .episode:
            return "點兩下開啟單集詳細資料"

        case .list:
            return "點兩下開啟片單"
        }
    }
}
