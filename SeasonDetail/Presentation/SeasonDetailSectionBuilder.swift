//
//  SeasonDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - SeasonDetailSectionBuilder

nonisolated enum SeasonDetailSectionBuilder {

    static func makeContent(content: SeasonDetailContent) -> SeasonDetailViewContent {
        let detail = SeasonDetailItem(detail: content.detail)

        return SeasonDetailViewContent(
            sections: makeSections(content: content, detail: detail),
            navigationTitle: detail.title
        )
    }

    private static func makeSections(
        content: SeasonDetailContent,
        detail: SeasonDetailItem
    ) -> [SeasonDetailSectionItem] {
        var sections: [SeasonDetailSectionItem] = [
            .overview(
                SeasonDetailOverviewSectionItem(
                    hero: detail,
                    overview: BaseDisplayTextFormatter.nonEmptyText(content.detail.overview)
                )
            )
        ]

        let facts = makeFacts(detail: content.detail, detailItem: detail)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let episodes = content.detail.episodes
            .sorted { $0.episodeNumber < $1.episodeNumber }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonEpisodeItem.init(episode:))
        if !episodes.isEmpty {
            sections.append(.episodes(episodes))
        }

        let videos = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { videoPriority($0) < videoPriority($1) }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonVideoItem.init(video:))
        if !videos.isEmpty {
            sections.append(.videos(Array(videos)))
        }

        let cast = makeCastItems(content: content)
        if !cast.isEmpty {
            sections.append(.cast(cast))
        }

        let crew = makeCrewItems(content: content)
        if !crew.isEmpty {
            sections.append(.crew(crew))
        }

        if let images = makeImageGalleryItem(images: content.images) {
            sections.append(.images(images))
        }

        if case .rated = content.accountStates.rated {
            sections.append(.accountState(SeasonAccountStateItem(accountStates: content.accountStates)))
        }

        let watchProviders = makeWatchProviderItems(response: content.watchProviders)
        if !watchProviders.isEmpty {
            sections.append(.watchProviders(watchProviders))
        }

        return sections
    }

    private static func makeFacts(
        detail: SeasonDetail,
        detailItem: SeasonDetailItem
    ) -> [SeasonDetailFactItem] {
        [
            makeFact(title: "季數", value: detailItem.seasonNumberText),
            makeFact(title: "集數", value: detailItem.episodeCountText),
            makeFact(title: "首播日期", value: BaseDisplayTextFormatter.nonEmptyText(detail.airDate)),
            makeFact(title: "評分", value: detail.voteAverage > 0 ? detailItem.scoreText : nil)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> SeasonDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return SeasonDetailFactItem(title: title, value: value)
    }

    private static func makeCastItems(content: SeasonDetailContent) -> [SeasonCastItem] {
        let aggregateCast = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonCastItem.init(aggregateCast:))

        if !aggregateCast.isEmpty {
            return Array(aggregateCast)
        }

        return Array(
            content.credits.cast
                .sorted { $0.order < $1.order }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map(SeasonCastItem.init(creditCast:))
        )
    }

    private static func makeCrewItems(content: SeasonDetailContent) -> [SeasonCrewItem] {
        let aggregateCrew = content.aggregateCredits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                return lhs.name < rhs.name
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonCrewItem.init(aggregateCrew:))

        if !aggregateCrew.isEmpty {
            return Array(aggregateCrew)
        }

        return Array(
            content.credits.crew
                .sorted { lhs, rhs in
                    if lhs.department != rhs.department {
                        return lhs.department < rhs.department
                    }

                    return lhs.name < rhs.name
                }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map(SeasonCrewItem.init(creditCrew:))
        )
    }

    private static func makeImageGalleryItem(images: TVImagesResponse) -> SeasonImageGalleryItem? {
        let posters = images.posters
            .filter { !$0.filePath.isEmpty }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonImageItem.init(image:))
        let backdrops = images.backdrops
            .filter { !$0.filePath.isEmpty }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonImageItem.init(image:))
        let logos = images.logos
            .filter { !$0.filePath.isEmpty }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(SeasonImageItem.init(image:))

        let item = SeasonImageGalleryItem(
            posters: Array(posters),
            backdrops: Array(backdrops),
            logos: Array(logos)
        )

        return item.isEmpty ? nil : item
    }

    private static func makeWatchProviderItems(
        response: TVWatchProvidersResponse,
        localization: AppLocalization = .current
    ) -> [SeasonWatchProviderItem] {
        let preferredRegionCode = localization.regionCode.uppercased()
        let preferredCountry = response.results[preferredRegionCode]
        let countries: [(key: String, value: TVWatchProviderCountry)]

        if let preferredCountry {
            countries = [(key: preferredRegionCode, value: preferredCountry)]
        } else {
            countries = response.results.sorted { $0.key < $1.key }
        }

        return countries
            .flatMap { countryCode, country in
                makeWatchProviderItems(countryCode: countryCode, country: country)
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { $0 }
    }

    private static func makeWatchProviderItems(
        countryCode: String,
        country: TVWatchProviderCountry
    ) -> [SeasonWatchProviderItem] {
        [
            makeWatchProviderItems(
                providers: country.flatrate,
                countryCode: countryCode,
                category: "串流",
                link: country.link
            ),
            makeWatchProviderItems(
                providers: country.rent,
                countryCode: countryCode,
                category: "租借",
                link: country.link
            ),
            makeWatchProviderItems(
                providers: country.buy,
                countryCode: countryCode,
                category: "購買",
                link: country.link
            ),
            makeWatchProviderItems(
                providers: country.free,
                countryCode: countryCode,
                category: "免費",
                link: country.link
            ),
            makeWatchProviderItems(
                providers: country.ads,
                countryCode: countryCode,
                category: "廣告",
                link: country.link
            )
        ].flatMap { $0 }
    }

    private static func makeWatchProviderItems(
        providers: [TVWatchProvider],
        countryCode: String,
        category: String,
        link: String
    ) -> [SeasonWatchProviderItem] {
        providers
            .sorted { lhs, rhs in
                if lhs.displayPriority != rhs.displayPriority {
                    return lhs.displayPriority < rhs.displayPriority
                }

                return lhs.name < rhs.name
            }
            .map {
                SeasonWatchProviderItem(
                    countryCode: countryCode,
                    provider: $0,
                    category: category,
                    link: link
                )
            }
    }

    private static func videoPriority(_ video: TVVideo) -> Int {
        switch video.type.lowercased() {
        case "trailer":
            return 0
        case "teaser":
            return 1
        case "clip":
            return 2
        default:
            return 3
        }
    }
}
