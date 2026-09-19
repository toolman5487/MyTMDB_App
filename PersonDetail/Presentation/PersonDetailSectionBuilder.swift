//
//  PersonDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - PersonDetailSectionBuilder

nonisolated enum PersonDetailSectionBuilder {

    static func makeSections(
        content: PersonDetailContent,
        localization: AppInterfaceLocalization
    ) -> [PersonDetailSectionItem] {
        let detailItem = PersonDetailItem(detail: content.detail, localization: localization)
        var sections: [PersonDetailSectionItem] = [
            .biography(
                PersonDetailBiographySectionItem(
                    hero: PersonDetailHeroItem(detail: detailItem),
                    biography: detailItem.biography
                )
            )
        ]

        let facts = makeFacts(detail: detailItem, localization: localization)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let movieCreditItems = PersonDetailCreditsPresentationBuilder.makePreviewItems(
            credits: content.combinedCredits,
            mediaType: .movie,
            localization: localization
        )
        if !movieCreditItems.isEmpty {
            sections.append(.movieCredits(movieCreditItems))
        }

        let tvCreditItems = PersonDetailCreditsPresentationBuilder.makePreviewItems(
            credits: content.combinedCredits,
            mediaType: .tv,
            localization: localization
        )
        if !tvCreditItems.isEmpty {
            sections.append(.tvCredits(tvCreditItems))
        }

        let profileImageItems = content.images.profiles
            .filter { !$0.filePath.isEmpty }
            .sorted { lhs, rhs in
                lhs.voteAverage > rhs.voteAverage
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(PersonDetailProfileImageItem.init(image:))
        if !profileImageItems.isEmpty {
            sections.append(.profileImages(Array(profileImageItems)))
        }

        let aliasItems = content.detail.alsoKnownAs
            .compactMap(BaseDisplayTextFormatter.nonEmptyText)
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(PersonDetailAliasItem.init(name:))
        if !aliasItems.isEmpty {
            sections.append(.aliases(Array(aliasItems)))
        }

        let externalLinks = makeExternalLinks(
            detail: detailItem,
            externalIDs: content.externalIDs,
            localization: localization
        )
        if !externalLinks.isEmpty {
            sections.append(.externalLinks(externalLinks))
        }

        return sections
    }

    private static func makeFacts(
        detail: PersonDetailItem,
        localization: AppInterfaceLocalization
    ) -> [PersonDetailFactItem] {
        [
            makeFact(
                title: localization.string("person_detail.fact.birthday", defaultValue: "Birthday"),
                value: detail.birthdayText
            ),
            makeFact(
                title: localization.string("person_detail.fact.deathday", defaultValue: "Died"),
                value: detail.deathdayText
            ),
            makeFact(
                title: localization.string("person_detail.fact.place_of_birth", defaultValue: "Place of Birth"),
                value: detail.placeOfBirthText
            ),
            makeFact(
                title: localization.string("person_detail.fact.known_for", defaultValue: "Known For"),
                value: detail.knownForDepartmentText
            ),
            makeFact(
                title: localization.string("person_detail.fact.gender", defaultValue: "Gender"),
                value: detail.genderText
            ),
            makeFact(
                title: localization.string("person_detail.fact.popularity", defaultValue: "Popularity"),
                value: detail.popularityText
            )
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> PersonDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return PersonDetailFactItem(title: title, value: value)
    }

    private static func makeExternalLinks(
        detail: PersonDetailItem,
        externalIDs: PersonExternalIDs,
        localization: AppInterfaceLocalization
    ) -> [PersonDetailExternalLinkItem] {
        [
            detail.homepageURL.map {
                PersonDetailExternalLinkItem(
                    id: "homepage",
                    title: localization.string(
                        "person_detail.link.homepage",
                        defaultValue: "Official Website"
                    ),
                    value: $0.absoluteString,
                    url: $0
                )
            },
            externalIDs.imdbID.flatMap {
                makeExternalLink(id: "imdb", title: "IMDb", value: $0, urlString: "https://www.imdb.com/name/\($0)")
            },
            externalIDs.instagramID.flatMap {
                makeExternalLink(id: "instagram", title: "Instagram", value: "@\($0)", urlString: "https://www.instagram.com/\($0)")
            },
            externalIDs.twitterID.flatMap {
                makeExternalLink(id: "twitter", title: "X", value: "@\($0)", urlString: "https://x.com/\($0)")
            },
            externalIDs.facebookID.flatMap {
                makeExternalLink(id: "facebook", title: "Facebook", value: $0, urlString: "https://www.facebook.com/\($0)")
            },
            externalIDs.tiktokID.flatMap {
                makeExternalLink(id: "tiktok", title: "TikTok", value: "@\($0)", urlString: "https://www.tiktok.com/@\($0)")
            },
            externalIDs.youtubeID.flatMap {
                makeExternalLink(id: "youtube", title: "YouTube", value: $0, urlString: "https://www.youtube.com/\($0)")
            },
            externalIDs.wikidataID.flatMap {
                makeExternalLink(id: "wikidata", title: "Wikidata", value: $0, urlString: "https://www.wikidata.org/wiki/\($0)")
            }
        ].compactMap { $0 }
    }

    private static func makeExternalLink(
        id: String,
        title: String,
        value: String,
        urlString: String
    ) -> PersonDetailExternalLinkItem? {
        guard let url = URL(string: urlString), !value.isEmpty else { return nil }
        return PersonDetailExternalLinkItem(id: id, title: title, value: value, url: url)
    }

}
