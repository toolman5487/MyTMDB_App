//
//  MovieDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - MovieDetailSectionBuilder

nonisolated enum MovieDetailSectionBuilder {

    static func makeSections(
        content: MovieDetailContent,
        apiLocalization: AppLocalization = .current,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [MovieDetailSectionItem] {
        let detailItem = MovieDetailItem(
            movie: content.movie,
            localization: interfaceLocalization
        )
        var sections: [MovieDetailSectionItem] = [
            .overview(
                MovieDetailOverviewSectionItem(
                    hero: MovieDetailHeroItem(
                        detail: detailItem,
                        localization: interfaceLocalization
                    ),
                    overview: detailItem.overview
                )
            )
        ]

        let facts = makeFacts(
            detail: detailItem,
            localization: interfaceLocalization
        )
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos
            .filter(\.isPlayable)
            .sorted { lhs, rhs in
                videoPriority(lhs) < videoPriority(rhs)
            }
            .map { MovieDetailVideoItem(video: $0, localization: interfaceLocalization) }
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(movie: content.movie) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.credits.cast
            .sorted { $0.order < $1.order }
            .map { MovieDetailCastItem(cast: $0, localization: interfaceLocalization) }
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let crewItems = content.credits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                if lhs.job != rhs.job {
                    return lhs.job < rhs.job
                }

                return lhs.name < rhs.name
            }
            .map { MovieDetailCrewItem(crew: $0, localization: interfaceLocalization) }
        if !crewItems.isEmpty {
            sections.append(.crew(Array(crewItems)))
        }

        let imageItems = content.images.backdrops.enumerated().compactMap { index, image in
            MovieDetailImageItem(
                image: image,
                index: index,
                localization: interfaceLocalization
            )
        }
        if !imageItems.isEmpty {
            sections.append(.images(imageItems))
        }

        if let collection = content.collection {
            let collectionItem = MovieDetailCollectionSectionItem(
                collection: collection,
                currentMovieID: content.movie.id,
                localization: interfaceLocalization
            )
            if !collectionItem.isEmpty {
                sections.append(.collection(collectionItem))
            }
        }

        let recommendationItems = content.recommendations.items
            .map {
                MovieDetailRecommendationItem(
                    recommendation: $0,
                    localization: interfaceLocalization
                )
            }
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        let similarItems = content.similar.items
            .map {
                MovieDetailSimilarItem(
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
        detail: MovieDetailItem,
        localization: AppInterfaceLocalization
    ) -> [MovieDetailFactItem] {
        [
            makeFact(
                title: localization.string("movie_detail.fact.release_date", defaultValue: "Release Date"),
                value: detail.releaseDateText
            ),
            makeFact(
                title: localization.string("movie_detail.fact.runtime", defaultValue: "Runtime"),
                value: detail.runtimeText
            ),
            makeFact(
                title: localization.string("detail.fact.status", defaultValue: "Status"),
                value: detail.statusText
            ),
            makeFact(
                title: localization.string("movie_detail.fact.budget", defaultValue: "Budget"),
                value: detail.budgetText
            ),
            makeFact(
                title: localization.string("movie_detail.fact.revenue", defaultValue: "Box Office"),
                value: detail.revenueText
            )
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> MovieDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return MovieDetailFactItem(title: title, value: value)
    }

    private static func makeAttributes(movie: Movie) -> MovieDetailAttributeSectionItem? {
        let genres = movie.genres.map(MovieDetailAttributeItem.init(genre:))
        let productionCompanies = movie.productionCompanies
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(MovieDetailAttributeItem.init(productionCompany:))
        let section = MovieDetailAttributeSectionItem(
            genres: genres,
            productionCompanies: Array(productionCompanies)
        )

        return section.isEmpty ? nil : section
    }

    private static func makeWatchProviderItems(
        providers: WatchProviders,
        apiLocalization: AppLocalization,
        interfaceLocalization: AppInterfaceLocalization
    ) -> [MovieWatchProviderItem] {
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
    ) -> [MovieWatchProviderItem] {
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
    ) -> [MovieWatchProviderItem] {
        providers
            .sorted { lhs, rhs in
                if lhs.displayPriority != rhs.displayPriority {
                    return lhs.displayPriority < rhs.displayPriority
                }

                return lhs.name < rhs.name
            }
            .map {
                MovieWatchProviderItem(
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
