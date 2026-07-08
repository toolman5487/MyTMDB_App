//
//  EpisodeDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation
import Observation

// MARK: - EpisodeDetailViewState

nonisolated enum EpisodeDetailViewState: Equatable {
    case idle
    case loading
    case loaded(EpisodeDetailViewContent)
    case failed(ErrorMessage)
}

// MARK: - EpisodeDetailViewContent

nonisolated struct EpisodeDetailViewContent: Sendable, Equatable {
    let sections: [EpisodeDetailSectionItem]
    let navigationTitle: String
}

// MARK: - EpisodeDetailViewModel

@MainActor
@Observable
final class EpisodeDetailViewModel {

    // MARK: - Properties

    private(set) var state: EpisodeDetailViewState = .idle

    private let service: EpisodeDetailServicing

    // MARK: - Initialization

    init(service: EpisodeDetailServicing = EpisodeDetailService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadEpisodeDetail(
        seriesID: Int,
        seasonNumber: Int,
        episodeNumber: Int
    ) async {
        guard seriesID > 0, seasonNumber >= 0, episodeNumber > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "資料錯誤",
                    message: "缺少有效的影集、季數或集數資訊。"
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchEpisodeDetailContent(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
            guard !Task.isCancelled else { return }

            state = .loaded(EpisodeDetailSectionBuilder.makeContent(content: content))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - EpisodeDetailSectionItem

nonisolated enum EpisodeDetailSectionItem: Sendable, Equatable {
    case overview(EpisodeDetailOverviewSectionItem)
    case facts([EpisodeDetailFactItem])
    case videos([EpisodeVideoItem])
    case cast([EpisodePersonItem])
    case guestStars([EpisodePersonItem])
    case crew([EpisodePersonItem])
    case images([EpisodeImageItem])
    case externalLinks([EpisodeExternalLinkItem])
    case accountState(EpisodeAccountStateItem)

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "集數資訊"

        case .videos:
            return "預告與影片"

        case .cast:
            return "主要演員"

        case .guestStars:
            return "客串演員"

        case .crew:
            return "幕後人員"

        case .images:
            return "劇照"

        case .externalLinks:
            return "相關連結"

        case .accountState:
            return "我的評分"
        }
    }
}

// MARK: - EpisodeDetailOverviewSectionItem

nonisolated struct EpisodeDetailOverviewSectionItem: Sendable, Equatable {
    let hero: EpisodeDetailItem
    let overview: String?
}

// MARK: - EpisodeDetailFactItem

nonisolated struct EpisodeDetailFactItem: Sendable, Equatable, Identifiable {
    var id: String {
        title
    }

    let title: String
    let value: String
}

// MARK: - EpisodeDetailSectionBuilder

nonisolated enum EpisodeDetailSectionBuilder {

    static func makeContent(content: EpisodeDetailContent) -> EpisodeDetailViewContent {
        let detail = EpisodeDetailItem(detail: content.detail)

        return EpisodeDetailViewContent(
            sections: makeSections(content: content, detail: detail),
            navigationTitle: detail.title
        )
    }

    private static func makeSections(
        content: EpisodeDetailContent,
        detail: EpisodeDetailItem
    ) -> [EpisodeDetailSectionItem] {
        var sections: [EpisodeDetailSectionItem] = [
            .overview(
                EpisodeDetailOverviewSectionItem(
                    hero: detail,
                    overview: content.detail.overview.isEmpty ? nil : content.detail.overview
                )
            )
        ]

        let facts = makeFacts(detail: detail, source: content.detail)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { videoPriority($0) < videoPriority($1) }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(EpisodeVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        let castItems = content.credits.cast
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(EpisodePersonItem.init(cast:))
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let guestStarItems = makeGuestStarItems(content: content)
        if !guestStarItems.isEmpty {
            sections.append(.guestStars(guestStarItems))
        }

        let crewItems = makeCrewItems(content: content)
        if !crewItems.isEmpty {
            sections.append(.crew(crewItems))
        }

        let imageItems = content.images.stills
            .filter { !$0.filePath.isEmpty }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(EpisodeImageItem.init(image:))
        if !imageItems.isEmpty {
            sections.append(.images(Array(imageItems)))
        }

        let externalLinks = makeExternalLinks(externalIDs: content.externalIDs)
        if !externalLinks.isEmpty {
            sections.append(.externalLinks(externalLinks))
        }

        if case .rated = content.accountStates.rated {
            sections.append(.accountState(EpisodeAccountStateItem(accountStates: content.accountStates)))
        }

        return sections
    }

    private static func makeFacts(
        detail: EpisodeDetailItem,
        source: EpisodeDetail
    ) -> [EpisodeDetailFactItem] {
        [
            makeFact(title: "季數", value: detail.seasonNumberText),
            makeFact(title: "集數", value: detail.episodeNumberText),
            makeFact(title: "首播日期", value: detail.airDateText),
            makeFact(title: "片長", value: detail.runtimeText),
            makeFact(title: "製作編號", value: detail.productionCodeText),
            makeFact(title: "評分", value: source.voteAverage > 0 ? detail.scoreText : nil),
            makeFact(title: "票數", value: source.voteCount > 0 ? detail.voteCountText : nil)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> EpisodeDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return EpisodeDetailFactItem(title: title, value: value)
    }

    private static func makeGuestStarItems(content: EpisodeDetailContent) -> [EpisodePersonItem] {
        let creditsGuestStars = content.credits.guestStars
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(EpisodePersonItem.init(cast:))

        if !creditsGuestStars.isEmpty {
            return Array(creditsGuestStars)
        }

        return Array(
            content.detail.guestStars
                .sorted { $0.order < $1.order }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map(EpisodePersonItem.init(cast:))
        )
    }

    private static func makeCrewItems(content: EpisodeDetailContent) -> [EpisodePersonItem] {
        let creditsCrew = content.credits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                return lhs.name < rhs.name
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(EpisodePersonItem.init(crew:))

        if !creditsCrew.isEmpty {
            return Array(creditsCrew)
        }

        return Array(
            content.detail.crew
                .sorted { lhs, rhs in
                    if lhs.department != rhs.department {
                        return lhs.department < rhs.department
                    }

                    return lhs.name < rhs.name
                }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map(EpisodePersonItem.init(crew:))
        )
    }

    private static func makeExternalLinks(externalIDs: EpisodeExternalIDsResponse) -> [EpisodeExternalLinkItem] {
        [
            makeIMDBLink(id: externalIDs.imdbID),
            makeWikidataLink(id: externalIDs.wikidataID)
        ].compactMap { $0 }
    }

    private static func makeIMDBLink(id: String?) -> EpisodeExternalLinkItem? {
        guard let id, !id.isEmpty, let url = URL(string: "https://www.imdb.com/title/\(id)") else {
            return nil
        }

        return EpisodeExternalLinkItem(id: "imdb", title: "IMDb", url: url)
    }

    private static func makeWikidataLink(id: String?) -> EpisodeExternalLinkItem? {
        guard let id, !id.isEmpty, let url = URL(string: "https://www.wikidata.org/wiki/\(id)") else {
            return nil
        }

        return EpisodeExternalLinkItem(id: "wikidata", title: "Wikidata", url: url)
    }

    private static func videoPriority(_ video: TVVideo) -> Int {
        let typeRank: Int
        switch video.type.lowercased() {
        case "trailer":
            typeRank = 0

        case "teaser":
            typeRank = 1

        case "clip":
            typeRank = 2

        default:
            typeRank = 3
        }

        let siteRank = video.site.lowercased() == "youtube" ? 0 : 1
        let officialRank = video.official ? 0 : 1

        return (typeRank * 100) + (siteRank * 10) + officialRank
    }
}
