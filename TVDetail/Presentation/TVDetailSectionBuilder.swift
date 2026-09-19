//
//  TVDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - TVDetailSectionBuilder

nonisolated enum TVDetailSectionBuilder {

    static func makeSections(
        content: TVDetailContent,
        apiLocalization: AppLocalization = .current,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [TVDetailSectionItem] {
        let detailItem = TVDetailItem(
            series: content.series,
            localization: interfaceLocalization
        )
        var sections: [TVDetailSectionItem] = [
            .overview(
                TVDetailOverviewSectionItem(
                    hero: TVDetailHeroItem(
                        detail: detailItem,
                        localization: interfaceLocalization
                    ),
                    overview: detailItem.overview
                )
            )
        ]

        let facts = makeFacts(detail: detailItem, localization: interfaceLocalization)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos
            .filter(\.isPlayable)
            .sorted { lhs, rhs in
                videoPriority(lhs) < videoPriority(rhs)
            }
            .map { TVDetailVideoItem(video: $0, localization: interfaceLocalization) }
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(series: content.series) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .map { TVDetailCastItem(cast: $0, localization: interfaceLocalization) }
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let crewItems = content.aggregateCredits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                let lhsJob = lhs.jobs.first ?? ""
                let rhsJob = rhs.jobs.first ?? ""
                if lhsJob != rhsJob {
                    return lhsJob < rhsJob
                }

                return lhs.name < rhs.name
            }
            .map { TVDetailCrewItem(crew: $0, localization: interfaceLocalization) }
        if !crewItems.isEmpty {
            sections.append(.crew(Array(crewItems)))
        }

        let seasonItems = content.series.seasons
            .sorted { $0.seasonNumber < $1.seasonNumber }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { TVDetailSeasonItem(season: $0, localization: interfaceLocalization) }
        if !seasonItems.isEmpty {
            sections.append(.seasons(Array(seasonItems)))
        }

        let imageItems = content.images.backdrops.enumerated().compactMap { index, image in
            TVDetailImageItem(
                image: image,
                index: index,
                localization: interfaceLocalization
            )
        }
        if !imageItems.isEmpty {
            sections.append(.images(imageItems))
        }

        let recommendationItems = content.recommendations.items
            .map {
                TVDetailRecommendationItem(
                    recommendation: $0,
                    localization: interfaceLocalization
                )
            }
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        let similarItems = content.similar.items
            .map {
                TVDetailSimilarItem(
                    recommendation: $0,
                    localization: interfaceLocalization
                )
            }
        if !similarItems.isEmpty {
            sections.append(.similar(Array(similarItems)))
        }

        let watchProviders = makeWatchProviderItems(
            providers: content.watchProviders,
            apiLocalization: apiLocalization,
            interfaceLocalization: interfaceLocalization
        )
        if !watchProviders.isEmpty {
            sections.append(.watchProviders(watchProviders))
        }

        return sections
    }

    private static func makeFacts(
        detail: TVDetailItem,
        localization: AppInterfaceLocalization
    ) -> [TVDetailFactItem] {
        [
            makeFact(title: localization.string("tv_detail.fact.first_air_date", defaultValue: "First Air Date"), value: detail.firstAirDateText),
            makeFact(title: localization.string("tv_detail.fact.last_air_date", defaultValue: "Last Air Date"), value: detail.lastAirDateText),
            makeFact(title: localization.string("tv_detail.fact.seasons", defaultValue: "Seasons"), value: detail.seasonCountText),
            makeFact(title: localization.string("tv_detail.fact.episodes", defaultValue: "Episodes"), value: detail.episodeCountText),
            makeFact(title: localization.string("tv_detail.fact.episode_runtime", defaultValue: "Episode Runtime"), value: detail.episodeRunTimeText),
            makeFact(title: localization.string("detail.fact.status", defaultValue: "Status"), value: detail.statusText),
            makeFact(title: localization.string("tv_detail.fact.type", defaultValue: "Type"), value: detail.typeText)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> TVDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return TVDetailFactItem(title: title, value: value)
    }

    private static func makeAttributes(series: TVSeries) -> TVDetailAttributeSectionItem? {
        let genres = series.genres.map(TVDetailAttributeItem.init(genre:))
        let productionCompanies = series.productionCompanies
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailAttributeItem.init(productionCompany:))
        let networks = series.networks
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailAttributeItem.init(network:))
        let section = TVDetailAttributeSectionItem(
            genres: genres,
            productionCompanies: Array(productionCompanies),
            networks: Array(networks)
        )

        return section.isEmpty ? nil : section
    }

    private static func makeWatchProviderItems(
        providers: WatchProviders,
        apiLocalization: AppLocalization,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [TVWatchProviderItem] {
        let preferredRegionCode = apiLocalization.regionCode.uppercased()
        let preferredCountry = providers.countries[preferredRegionCode]
        let countries: [(key: String, value: WatchProviderCountry)]

        if let preferredCountry {
            countries = [(key: preferredRegionCode, value: preferredCountry)]
        } else {
            countries = providers.countries.sorted { $0.key < $1.key }
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
    ) -> [TVWatchProviderItem] {
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
    ) -> [TVWatchProviderItem] {
        providers
            .sorted { lhs, rhs in
                if lhs.displayPriority != rhs.displayPriority {
                    return lhs.displayPriority < rhs.displayPriority
                }

                return lhs.name < rhs.name
            }
            .map {
                TVWatchProviderItem(
                    countryCode: countryCode,
                    provider: $0,
                    category: category,
                    link: link,
                    localization: localization
                )
            }
    }

    private static func videoPriority(_ video: Video) -> Int {
        let typeRank: Int
        switch video.type.lowercased() {
        case "trailer":
            typeRank = 0

        case "teaser":
            typeRank = 1

        default:
            typeRank = 2
        }

        let siteRank = video.site.lowercased() == "youtube" ? 0 : 1
        let officialRank = video.isOfficial ? 0 : 1

        return (typeRank * 100) + (siteRank * 10) + officialRank
    }
}
