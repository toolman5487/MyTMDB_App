//
//  SeasonDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - SeasonDetailSectionBuilder

nonisolated enum SeasonDetailSectionBuilder {

    static func makeContent(
        content: SeasonDetailContent,
        apiLocalization: AppLocalization = .current,
        interfaceLocalization: AppInterfaceLocalization
    ) -> SeasonDetailViewContent {
        let detail = SeasonDetailItem(
            detail: content.detail,
            localization: interfaceLocalization
        )

        return SeasonDetailViewContent(
            sections: makeSections(
                content: content,
                detail: detail,
                apiLocalization: apiLocalization,
                interfaceLocalization: interfaceLocalization
            ),
            navigationTitle: detail.title
        )
    }

    private static func makeSections(
        content: SeasonDetailContent,
        detail: SeasonDetailItem,
        apiLocalization: AppLocalization,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [SeasonDetailSectionItem] {
        var sections: [SeasonDetailSectionItem] = [
            .overview(
                SeasonDetailOverviewSectionItem(
                    hero: detail,
                    overview: BaseDisplayTextFormatter.nonEmptyText(content.detail.overview)
                )
            )
        ]

        let facts = makeFacts(
            detail: content.detail,
            detailItem: detail,
            localization: interfaceLocalization
        )
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let episodes = content.detail.episodes
            .sorted { $0.episodeNumber < $1.episodeNumber }
            .map { SeasonEpisodeItem(episode: $0, localization: interfaceLocalization) }
        if !episodes.isEmpty {
            sections.append(.episodes(episodes))
        }

        let videos = content.videos
            .filter { !$0.key.isEmpty }
            .sorted { videoPriority($0) < videoPriority($1) }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { SeasonVideoItem(video: $0, localization: interfaceLocalization) }
        if !videos.isEmpty {
            sections.append(.videos(Array(videos)))
        }

        let cast = makeCastItems(content: content, localization: interfaceLocalization)
        if !cast.isEmpty {
            sections.append(.cast(cast))
        }

        let crew = makeCrewItems(content: content, localization: interfaceLocalization)
        if !crew.isEmpty {
            sections.append(.crew(crew))
        }

        if let images = makeImageGalleryItem(images: content.images) {
            sections.append(.images(images))
        }

        if case .rated = content.accountState.rating {
            sections.append(.accountState(SeasonAccountStateItem(
                accountState: content.accountState,
                localization: interfaceLocalization
            )))
        }

        let watchProviders = makeWatchProviderItems(
            response: content.watchProviders,
            apiLocalization: apiLocalization,
            interfaceLocalization: interfaceLocalization
        )
        if !watchProviders.isEmpty {
            sections.append(.watchProviders(watchProviders))
        }

        return sections
    }

    private static func makeFacts(
        detail: Season,
        detailItem: SeasonDetailItem,
        localization: AppInterfaceLocalization
    ) -> [SeasonDetailFactItem] {
        [
            makeFact(title: localization.string("season_detail.fact.season", defaultValue: "Season"), value: detailItem.seasonNumberText),
            makeFact(title: localization.string("season_detail.fact.episodes", defaultValue: "Episodes"), value: detailItem.episodeCountText),
            makeFact(
                title: localization.string("season_detail.fact.air_date", defaultValue: "Air Date"),
                value: BaseDisplayTextFormatter.isoDayText(from: detail.airDate)
            ),
            makeFact(title: localization.string("common.rating.label", defaultValue: "Rating"), value: detail.voteAverage > 0 ? detailItem.scoreText : nil)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> SeasonDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return SeasonDetailFactItem(title: title, value: value)
    }

    private static func makeCastItems(
        content: SeasonDetailContent,
        localization: AppInterfaceLocalization
    ) -> [SeasonCastItem] {
        let aggregateCast = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { SeasonCastItem(aggregateCast: $0, localization: localization) }

        if !aggregateCast.isEmpty {
            return Array(aggregateCast)
        }

        return Array(
            content.credits.cast
                .sorted { $0.order < $1.order }
                .prefix(DetailSectionPreviewLimit.itemCount)
                .map { SeasonCastItem(creditCast: $0, localization: localization) }
        )
    }

    private static func makeCrewItems(
        content: SeasonDetailContent,
        localization: AppInterfaceLocalization
    ) -> [SeasonCrewItem] {
        let aggregateCrew = content.aggregateCredits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                return lhs.name < rhs.name
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { SeasonCrewItem(aggregateCrew: $0, localization: localization) }

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
                .map { SeasonCrewItem(creditCrew: $0, localization: localization) }
        )
    }

    private static func makeImageGalleryItem(images: MediaImages) -> SeasonImageGalleryItem? {
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
        response: WatchProviders,
        apiLocalization: AppLocalization,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [SeasonWatchProviderItem] {
        let preferredRegionCode = apiLocalization.regionCode.uppercased()
        let preferredCountry = response.countries[preferredRegionCode]
        let countries: [(key: String, value: WatchProviderCountry)]

        if let preferredCountry {
            countries = [(key: preferredRegionCode, value: preferredCountry)]
        } else {
            countries = response.countries.sorted { $0.key < $1.key }
        }

        return countries
            .flatMap { countryCode, country in
                makeWatchProviderItems(
                    countryCode: countryCode,
                    country: country,
                    localization: interfaceLocalization
                )
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { $0 }
    }

    private static func makeWatchProviderItems(
        countryCode: String,
        country: WatchProviderCountry,
        localization: AppInterfaceLocalization
    ) -> [SeasonWatchProviderItem] {
        [
            makeWatchProviderItems(
                providers: country.flatrate,
                countryCode: countryCode,
                category: localization.string("watch_provider.category.stream", defaultValue: "Stream"),
                link: country.link,
                localization: localization
            ),
            makeWatchProviderItems(
                providers: country.rent,
                countryCode: countryCode,
                category: localization.string("watch_provider.category.rent", defaultValue: "Rent"),
                link: country.link,
                localization: localization
            ),
            makeWatchProviderItems(
                providers: country.buy,
                countryCode: countryCode,
                category: localization.string("watch_provider.category.buy", defaultValue: "Buy"),
                link: country.link,
                localization: localization
            ),
            makeWatchProviderItems(
                providers: country.free,
                countryCode: countryCode,
                category: localization.string("watch_provider.category.free", defaultValue: "Free"),
                link: country.link,
                localization: localization
            ),
            makeWatchProviderItems(
                providers: country.ads,
                countryCode: countryCode,
                category: localization.string("watch_provider.category.ads", defaultValue: "With Ads"),
                link: country.link,
                localization: localization
            )
        ].flatMap { $0 }
    }

    private static func makeWatchProviderItems(
        providers: [WatchProvider],
        countryCode: String,
        category: String,
        link: String,
        localization: AppInterfaceLocalization
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
                    link: link,
                    localization: localization
                )
            }
    }

    private static func videoPriority(_ video: Video) -> Int {
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
