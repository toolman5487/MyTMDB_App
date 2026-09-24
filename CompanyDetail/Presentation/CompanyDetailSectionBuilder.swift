//
//  CompanyDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailSectionBuilder

nonisolated enum CompanyDetailSectionBuilder {

    static func makeSections(
        content: CompanyDetailContent,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailSectionItem] {
        let detailItem = CompanyDetailItem(detail: content.detail, localization: localization)

        var sections: [CompanyDetailSectionItem] = [
            .header(
                CompanyDetailHeaderSectionItem(
                    hero: CompanyDetailHeroItem(detail: detailItem),
                    description: detailItem.description
                )
            )
        ]

        let facts = makeFacts(detail: detailItem, localization: localization)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let movieItems = content.movies.items
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { CompanyDetailMediaItem(summary: $0, mediaKind: .movie, localization: localization) }
        if !movieItems.isEmpty {
            sections.append(.movies(Array(movieItems)))
        }

        let tvItems = content.tvShows.items
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map { CompanyDetailMediaItem(summary: $0, mediaKind: .tv, localization: localization) }
        if !tvItems.isEmpty {
            sections.append(.tvShows(Array(tvItems)))
        }

        let logoItems = content.images.logos
            .filter { !$0.isVectorFormat }
            .sorted { $0.voteAverage > $1.voteAverage }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(CompanyDetailLogoItem.init(logo:))
        if !logoItems.isEmpty {
            sections.append(.logos(Array(logoItems)))
        }

        let alternativeNameItems = content.alternativeNames
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(CompanyDetailAlternativeNameItem.init(alternativeName:))
        if !alternativeNameItems.isEmpty {
            sections.append(.alternativeNames(Array(alternativeNameItems)))
        }

        let externalLinks = makeExternalLinks(detail: detailItem, localization: localization)
        if !externalLinks.isEmpty {
            sections.append(.externalLinks(externalLinks))
        }

        return sections
    }

    private static func makeFacts(
        detail: CompanyDetailItem,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailFactItem] {
        [
            makeFact(
                title: localization.string("company_detail.fact.headquarters", defaultValue: "Headquarters"),
                value: detail.headquartersText
            ),
            makeFact(
                title: localization.string("company_detail.fact.origin_country", defaultValue: "Origin Country"),
                value: detail.originCountryText
            ),
            makeFact(
                title: localization.string("company_detail.fact.parent_company", defaultValue: "Parent Company"),
                value: detail.parentCompanyText
            )
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> CompanyDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return CompanyDetailFactItem(title: title, value: value)
    }

    private static func makeExternalLinks(
        detail: CompanyDetailItem,
        localization: AppInterfaceLocalization
    ) -> [CompanyDetailExternalLinkItem] {
        [
            detail.homepageURL.map {
                CompanyDetailExternalLinkItem(
                    id: "homepage",
                    title: localization.string("company_detail.link.homepage", defaultValue: "Official Website"),
                    value: $0.absoluteString,
                    url: $0
                )
            }
        ].compactMap { $0 }
    }
}
