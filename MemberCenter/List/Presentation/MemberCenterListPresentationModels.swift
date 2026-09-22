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
    private(set) var pagination: MediaGridPaginationState

    func updatingLoadingNextPage(_ isLoading: Bool) -> MemberCenterListContent {
        var content = self
        content.pagination = pagination.updatingLoadingNextPage(isLoading)
        return content
    }

    func appending(_ nextContent: MemberCenterListContent) -> MemberCenterListContent {
        MemberCenterListContent(
            destination: nextContent.destination,
            items: items + nextContent.items,
            pagination: nextContent.pagination.updatingLoadingNextPage(false)
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
    let accessibilityText: AccessibilityText

    init(
        item: AccountCollectionItem,
        destination: MemberCenterDestination,
        localization: AppInterfaceLocalization
    ) {
        let untitledText = localization.string("common.fallback.untitled", defaultValue: "Untitled")

        switch item {
        case .media(let summary, let kind):
            self.id = Self.identifier(destination: destination, kind: kind, mediaID: summary.id)
            self.title = BaseDisplayTextFormatter.text(summary.title, fallback: untitledText)
            self.subtitle = Self.dateText(summary.releaseDate, localization: localization)
            self.metadataText = BaseDisplayTextFormatter.ratingText(
                summary.voteAverage,
                localization: localization
            )
            self.imageURL = Self.posterURL(path: summary.posterPath)
            self.detailTarget = Self.detailTarget(kind: kind, mediaID: summary.id)

        case .ratedMedia(let ratedMedia):
            self.id = Self.identifier(
                destination: destination,
                kind: ratedMedia.kind,
                mediaID: ratedMedia.summary.id
            )
            self.title = BaseDisplayTextFormatter.text(ratedMedia.summary.title, fallback: untitledText)
            self.subtitle = Self.dateText(ratedMedia.summary.releaseDate, localization: localization)
            self.metadataText = BaseDisplayTextFormatter.userRatingText(
                ratedMedia.rating,
                localization: localization
            )
            self.imageURL = Self.posterURL(path: ratedMedia.summary.posterPath)
            self.detailTarget = Self.detailTarget(
                kind: ratedMedia.kind,
                mediaID: ratedMedia.summary.id
            )

        case .ratedEpisode(let episode):
            self.id = "\(destination.rawValue)-episode-\(episode.seriesID)-\(episode.seasonNumber)-\(episode.episodeNumber)-\(episode.id)"
            self.title = BaseDisplayTextFormatter.text(episode.name, fallback: untitledText)
            self.subtitle = Self.episodeSubtitle(episode, localization: localization)
            self.metadataText = BaseDisplayTextFormatter.userRatingText(
                episode.rating,
                localization: localization
            )
            self.imageURL = Self.posterURL(path: episode.stillPath)
            self.detailTarget = .episode(
                seriesID: episode.seriesID,
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber
            )

        case .list(let list):
            self.id = "\(destination.rawValue)-list-\(list.id)"
            self.title = BaseDisplayTextFormatter.text(
                list.name,
                fallback: localization.string("member_center.list.untitled", defaultValue: "Untitled List")
            )
            self.subtitle = list.description.isEmpty
                ? localization.string("member_center.list.no_description", defaultValue: "No description")
                : list.description
            self.metadataText = BaseDisplayTextFormatter.countText(
                list.itemCount,
                unit: .items,
                localization: localization
            )
            self.imageURL = Self.posterURL(path: list.posterPath)
            self.detailTarget = .list(id: list.id)
        }

        self.accessibilityText = AccessibilityText(
            label: title,
            value: BaseDisplayTextFormatter.metadata([
                subtitle,
                metadataText
            ]),
            hint: Self.accessibilityHint(for: detailTarget, localization: localization)
        )
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

    private static func dateText(
        _ day: CalendarDay?,
        localization: AppInterfaceLocalization
    ) -> String {
        BaseDisplayTextFormatter.announcedText(
            BaseDisplayTextFormatter.isoDayText(from: day),
            localization: localization
        )
    }

    private static func posterURL(path: String?) -> URL? {
        path.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    private static func episodeSubtitle(
        _ episode: RatedEpisode,
        localization: AppInterfaceLocalization
    ) -> String {
        BaseDisplayTextFormatter.metadata([
            BaseDisplayTextFormatter.seasonEpisodeNumberText(
                seasonNumber: episode.seasonNumber,
                episodeNumber: episode.episodeNumber,
                localization: localization
            ),
            BaseDisplayTextFormatter.isoDayText(from: episode.airDate)
        ]) ?? ""
    }

    private static func accessibilityHint(
        for detailTarget: MemberCenterListItemDetailTarget,
        localization: AppInterfaceLocalization
    ) -> String {
        switch detailTarget {
        case .movie:
            return MediaKind.movie.detailAccessibilityHint(localization: localization)

        case .tv:
            return MediaKind.tv.detailAccessibilityHint(localization: localization)

        case .episode:
            return localization.string(
                "common.accessibility.open_episode_detail.hint",
                defaultValue: "Double-tap to open episode details"
            )

        case .list:
            return localization.string(
                "member_center.list.accessibility_hint",
                defaultValue: "Double-tap to open the list"
            )
        }
    }
}
