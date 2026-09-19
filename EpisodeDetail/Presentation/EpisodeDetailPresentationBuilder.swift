//
//  EpisodeDetailPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/19.
//

import Foundation

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

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return localization.string("episode_detail.section.information", defaultValue: "Episode Information")

        case .videos:
            return localization.string("detail.section.videos", defaultValue: "Trailers and Videos")

        case .cast:
            return localization.string("detail.section.cast", defaultValue: "Cast")

        case .guestStars:
            return localization.string("episode_detail.section.guest_stars", defaultValue: "Guest Stars")

        case .crew:
            return localization.string("detail.section.crew", defaultValue: "Crew")

        case .images:
            return localization.string("detail.section.images", defaultValue: "Images")

        case .externalLinks:
            return localization.string("detail.section.external_links", defaultValue: "Related Links")

        case .accountState:
            return localization.string("common.rating.my_rating", defaultValue: "My Rating")
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

// MARK: - EpisodeDetailPresentationBuilder

nonisolated enum EpisodeDetailPresentationBuilder {

    static func makeContent(
        content: EpisodeDetailContent,
        localization: AppInterfaceLocalization
    ) -> EpisodeDetailViewContent {
        let detail = EpisodeDetailItem(detail: content.detail, localization: localization)

        return EpisodeDetailViewContent(
            sections: makeSections(
                content: content,
                detail: detail,
                localization: localization
            ),
            navigationTitle: detail.title
        )
    }

    static func updatingAccountState(
        value: Double?,
        in content: EpisodeDetailViewContent
    ) -> EpisodeDetailViewContent {
        var sections = content.sections.filter { section in
            if case .accountState = section {
                return false
            }

            return true
        }

        if let value {
            sections.append(.accountState(EpisodeAccountStateItem(value: value)))
        }

        return EpisodeDetailViewContent(
            sections: sections,
            navigationTitle: content.navigationTitle
        )
    }

    private static func makeSections(
        content: EpisodeDetailContent,
        detail: EpisodeDetailItem,
        localization: AppInterfaceLocalization
    ) -> [EpisodeDetailSectionItem] {
        var sections: [EpisodeDetailSectionItem] = [
            .overview(
                EpisodeDetailOverviewSectionItem(
                    hero: detail,
                    overview: BaseDisplayTextFormatter.nonEmptyText(content.detail.overview)
                )
            )
        ]

        let facts = makeFacts(
            detail: detail,
            source: content.detail,
            localization: localization
        )
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos
            .filter { !$0.key.isEmpty }
            .sorted { videoPriority($0) < videoPriority($1) }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { EpisodeVideoItem(video: $0, localization: localization) }
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        let castItems = content.credits.cast
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { EpisodePersonItem(cast: $0, localization: localization) }
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let guestStarItems = makeGuestStarItems(content: content, localization: localization)
        if !guestStarItems.isEmpty {
            sections.append(.guestStars(guestStarItems))
        }

        let crewItems = makeCrewItems(content: content, localization: localization)
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

        if content.supportsAccountRating, case .rated = content.accountState.rating {
            sections.append(.accountState(EpisodeAccountStateItem(
                accountState: content.accountState,
                localization: localization
            )))
        }

        return sections
    }

    private static func makeFacts(
        detail: EpisodeDetailItem,
        source: Episode,
        localization: AppInterfaceLocalization
    ) -> [EpisodeDetailFactItem] {
        [
            makeFact(
                title: localization.string("season_detail.fact.season", defaultValue: "Season"),
                value: detail.seasonNumberText
            ),
            makeFact(
                title: localization.string("episode_detail.fact.episode", defaultValue: "Episode"),
                value: detail.episodeNumberText
            ),
            makeFact(
                title: localization.string("season_detail.fact.air_date", defaultValue: "Air Date"),
                value: detail.airDateText
            ),
            makeFact(
                title: localization.string("movie_detail.fact.runtime", defaultValue: "Runtime"),
                value: detail.runtimeText
            ),
            makeFact(
                title: localization.string("episode_detail.fact.production_code", defaultValue: "Production Code"),
                value: detail.productionCodeText
            ),
            makeFact(
                title: localization.string("common.rating.label", defaultValue: "Rating"),
                value: source.voteAverage > 0 ? detail.scoreText : nil
            ),
            makeFact(
                title: localization.string("episode_detail.fact.vote_count", defaultValue: "Votes"),
                value: source.voteCount > 0 ? detail.voteCountText : nil
            )
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> EpisodeDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return EpisodeDetailFactItem(title: title, value: value)
    }

    private static func makeGuestStarItems(
        content: EpisodeDetailContent,
        localization: AppInterfaceLocalization
    ) -> [EpisodePersonItem] {
        let creditsGuestStars = content.credits.guestStars
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { EpisodePersonItem(cast: $0, localization: localization) }

        if !creditsGuestStars.isEmpty {
            return Array(creditsGuestStars)
        }

        return Array(
            content.detail.guestStars
                .sorted { $0.order < $1.order }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map { EpisodePersonItem(cast: $0, localization: localization) }
        )
    }

    private static func makeCrewItems(
        content: EpisodeDetailContent,
        localization: AppInterfaceLocalization
    ) -> [EpisodePersonItem] {
        let creditsCrew = content.credits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                return lhs.name < rhs.name
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { EpisodePersonItem(crew: $0, localization: localization) }

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
                .map { EpisodePersonItem(crew: $0, localization: localization) }
        )
    }

    private static func makeExternalLinks(externalIDs: EpisodeExternalIDs) -> [EpisodeExternalLinkItem] {
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

    private static func videoPriority(_ video: Video) -> Int {
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
        let officialRank = video.isOfficial ? 0 : 1

        return (typeRank * 100) + (siteRank * 10) + officialRank
    }
}
