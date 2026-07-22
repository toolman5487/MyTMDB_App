//
//  MovieDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - MovieDetailSectionBuilder

nonisolated enum MovieDetailSectionBuilder {

    static func makeSections(content: MovieDetailContent) -> [MovieDetailSectionItem] {
        let detailItem = MovieDetailItem(detail: content.detail)
        var sections: [MovieDetailSectionItem] = [
            .overview(
                MovieDetailOverviewSectionItem(
                    hero: MovieDetailHeroItem(detail: detailItem),
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
            .map(MovieDetailVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(detail: content.detail) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.credits.cast
            .sorted { $0.order < $1.order }
            .map(MovieDetailCastItem.init(cast:))
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let imageItems = content.images.backdrops.enumerated().compactMap { index, image in
            MovieDetailImageItem(image: image, index: index)
        }
        if !imageItems.isEmpty {
            sections.append(.images(imageItems))
        }

        let recommendationItems = content.recommendations.results
            .map(MovieDetailRecommendationItem.init(recommendation:))
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        return sections
    }

    private static func makeFacts(detail: MovieDetailItem) -> [MovieDetailFactItem] {
        [
            makeFact(title: "上映日", value: detail.releaseDateText),
            makeFact(title: "片長", value: detail.runtimeText),
            makeFact(title: "狀態", value: detail.statusText),
            makeFact(title: "預算", value: detail.budgetText),
            makeFact(title: "票房", value: detail.revenueText)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> MovieDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return MovieDetailFactItem(title: title, value: value)
    }

    private static func makeAttributes(detail: MovieDetail) -> MovieDetailAttributeSectionItem? {
        let genres = detail.genres.map(MovieDetailAttributeItem.init(genre:))
        let productionCompanies = detail.productionCompanies
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(MovieDetailAttributeItem.init(productionCompany:))
        let section = MovieDetailAttributeSectionItem(
            genres: genres,
            productionCompanies: Array(productionCompanies)
        )

        return section.isEmpty ? nil : section
    }

    private static func videoPriority(_ video: MovieVideo) -> Int {
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
