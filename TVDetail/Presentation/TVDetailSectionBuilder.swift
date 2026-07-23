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
        localization: AppLocalization = .current
    ) -> [TVDetailSectionItem] {
        let detailItem = TVDetailItem(detail: content.detail)
        var sections: [TVDetailSectionItem] = [
            .overview(
                TVDetailOverviewSectionItem(
                    hero: TVDetailHeroItem(detail: detailItem),
                    overview: detailItem.overview
                )
            )
        ]

        let facts = makeFacts(detail: detailItem)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { lhs, rhs in
                videoPriority(lhs) < videoPriority(rhs)
            }
            .map(TVDetailVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(detail: content.detail) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .map(TVDetailCastItem.init(cast:))
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let seasonItems = content.detail.seasons
            .sorted { $0.seasonNumber < $1.seasonNumber }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailSeasonItem.init(season:))
        if !seasonItems.isEmpty {
            sections.append(.seasons(Array(seasonItems)))
        }

        let imageItems = content.images.backdrops.enumerated().compactMap { index, image in
            TVDetailImageItem(image: image, index: index)
        }
        if !imageItems.isEmpty {
            sections.append(.images(imageItems))
        }

        let recommendationItems = content.recommendations.results
            .map(TVDetailRecommendationItem.init(recommendation:))
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        let similarItems = content.similar.results
            .map(TVDetailSimilarItem.init(recommendation:))
        if !similarItems.isEmpty {
            sections.append(.similar(Array(similarItems)))
        }

        let watchProviders = makeWatchProviderItems(
            response: content.watchProviders,
            localization: localization
        )
        if !watchProviders.isEmpty {
            sections.append(.watchProviders(watchProviders))
        }

        return sections
    }

    private static func makeFacts(detail: TVDetailItem) -> [TVDetailFactItem] {
        [
            makeFact(title: "首播日", value: detail.firstAirDateText),
            makeFact(title: "最後播出", value: detail.lastAirDateText),
            makeFact(title: "季數", value: detail.seasonCountText),
            makeFact(title: "集數", value: detail.episodeCountText),
            makeFact(title: "單集長度", value: detail.episodeRunTimeText),
            makeFact(title: "狀態", value: detail.statusText),
            makeFact(title: "類型", value: detail.typeText)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> TVDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return TVDetailFactItem(title: title, value: value)
    }

    private static func makeAttributes(detail: TVDetail) -> TVDetailAttributeSectionItem? {
        let genres = detail.genres.map(TVDetailAttributeItem.init(genre:))
        let productionCompanies = detail.productionCompanies
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailAttributeItem.init(productionCompany:))
        let networks = detail.networks
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
        response: TVWatchProvidersResponse,
        localization: AppLocalization = .current
    ) -> [TVWatchProviderItem] {
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
    ) -> [TVWatchProviderItem] {
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
                    link: link
                )
            }
    }

    private static func videoPriority(_ video: TVVideo) -> Int {
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
        let officialRank = video.official ? 0 : 1

        return (typeRank * 100) + (siteRank * 10) + officialRank
    }
}
