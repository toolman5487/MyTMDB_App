//
//  PersonDetailSectionBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

// MARK: - PersonDetailSectionBuilder

nonisolated enum PersonDetailSectionBuilder {

    static func makeSections(content: PersonDetailContent) -> [PersonDetailSectionItem] {
        let detailItem = PersonDetailItem(detail: content.detail)
        var sections: [PersonDetailSectionItem] = [
            .biography(
                PersonDetailBiographySectionItem(
                    hero: PersonDetailHeroItem(detail: detailItem),
                    biography: detailItem.biography
                )
            )
        ]

        let facts = makeFacts(detail: detailItem)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let knownForItems = content.combinedCredits.cast
            .sorted { lhs, rhs in
                creditPriority(lhs) > creditPriority(rhs)
            }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(PersonDetailCreditItem.init(cast:))
        if !knownForItems.isEmpty {
            sections.append(.knownFor(Array(knownForItems)))
        }

        let crewItems = content.combinedCredits.crew
            .sorted { lhs, rhs in
                creditPriority(lhs) > creditPriority(rhs)
            }
            .uniqueByContent()
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(PersonDetailCreditItem.init(crew:))
        if !crewItems.isEmpty {
            sections.append(.crew(Array(crewItems)))
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

        let externalLinks = makeExternalLinks(detail: detailItem, externalIDs: content.externalIDs)
        if !externalLinks.isEmpty {
            sections.append(.externalLinks(externalLinks))
        }

        return sections
    }

    private static func makeFacts(detail: PersonDetailItem) -> [PersonDetailFactItem] {
        [
            makeFact(title: "生日", value: detail.birthdayText),
            makeFact(title: "逝世", value: detail.deathdayText),
            makeFact(title: "出生地", value: detail.placeOfBirthText),
            makeFact(title: "主要部門", value: detail.knownForDepartmentText),
            makeFact(title: "性別", value: detail.genderText),
            makeFact(title: "人氣", value: detail.popularityText)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> PersonDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return PersonDetailFactItem(title: title, value: value)
    }

    private static func makeExternalLinks(
        detail: PersonDetailItem,
        externalIDs: PersonExternalIDs
    ) -> [PersonDetailExternalLinkItem] {
        [
            detail.homepageURL.map {
                PersonDetailExternalLinkItem(id: "homepage", title: "官方網站", value: $0.absoluteString, url: $0)
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

    private static func creditPriority(_ credit: PersonCombinedCreditCast) -> Double {
        credit.popularity + credit.voteAverage + Double(credit.voteCount) / 1_000
    }

    private static func creditPriority(_ credit: PersonCombinedCreditCrew) -> Double {
        credit.popularity + credit.voteAverage + Double(credit.voteCount) / 1_000
    }
}

private extension Sequence where Element == PersonCombinedCreditCrew {

    func uniqueByContent() -> [PersonCombinedCreditCrew] {
        var seenIDs = Set<String>()

        return filter { credit in
            let id = "\(credit.mediaType.idValue)-\(credit.id)"
            return seenIDs.insert(id).inserted
        }
    }
}
