//
//  PersonDetailCreditsPresentationBuilder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import Foundation

// MARK: - PersonDetailCreditsPresentationBuilder

nonisolated enum PersonDetailCreditsPresentationBuilder {

    static func makePreviewItems(
        credits: PersonCredits,
        mediaType: PersonCreditMediaType,
        localization: AppInterfaceLocalization
    ) -> [PersonDetailCreditItem] {
        Array(
            makeItems(
                credits: credits,
                mediaType: mediaType,
                allowsUnknownMediaType: false,
                localization: localization
            )
                .prefix(DetailSectionPreviewLimit.itemCount)
        )
    }

    static func makeContentListConfiguration(
        credits: PersonCredits,
        mediaType: PersonCreditMediaType,
        localization: AppInterfaceLocalization
    ) -> DetailContentListConfiguration {
        let title = mediaType.creditsTitle(localization: localization)
        let items = makeItems(
            credits: credits,
            mediaType: mediaType,
            allowsUnknownMediaType: true,
            localization: localization
        )

        return DetailContentListConfiguration(
            title: title,
            thumbnailStyle: .portrait,
            items: items.map { item in
                DetailContentListItem(
                    id: item.id,
                    imageURL: item.posterURL,
                    title: item.title,
                    subtitle: BaseDisplayTextFormatter.metadata([
                        item.dateText,
                        roleText(for: item, localization: localization),
                        BaseDisplayTextFormatter.ratingText(item.scoreText, localization: localization)
                    ]),
                    destination: destination(for: item)
                )
            }
        )
    }

    private static func makeItems(
        credits: PersonCredits,
        mediaType: PersonCreditMediaType,
        allowsUnknownMediaType: Bool,
        localization: AppInterfaceLocalization
    ) -> [PersonDetailCreditItem] {
        let castCandidates = credits.cast
            .filter {
                matches(
                    $0.mediaType,
                    expected: mediaType,
                    allowsUnknown: allowsUnknownMediaType
                )
            }
            .map {
                CreditCandidate(
                    item: PersonDetailCreditItem(
                        cast: $0,
                        mediaType: mediaType,
                        localization: localization
                    ),
                    priority: creditPriority($0)
                )
            }
        let crewCandidates = credits.crew
            .filter {
                matches(
                    $0.mediaType,
                    expected: mediaType,
                    allowsUnknown: allowsUnknownMediaType
                )
            }
            .map {
                CreditCandidate(
                    item: PersonDetailCreditItem(
                        crew: $0,
                        mediaType: mediaType,
                        localization: localization
                    ),
                    priority: creditPriority($0)
                )
            }

        var seenSourceIDs = Set<Int>()

        return (castCandidates + crewCandidates)
            .sorted { $0.priority > $1.priority }
            .compactMap { candidate in
                guard seenSourceIDs.insert(candidate.item.sourceID).inserted else {
                    return nil
                }

                return candidate.item
            }
    }

    private static func matches(
        _ actualMediaType: PersonCreditMediaType,
        expected expectedMediaType: PersonCreditMediaType,
        allowsUnknown: Bool
    ) -> Bool {
        switch actualMediaType {
        case .unknown:
            return allowsUnknown

        case .movie, .tv:
            return actualMediaType == expectedMediaType
        }
    }

    private static func creditPriority(_ credit: PersonCreditCast) -> Double {
        credit.popularity + credit.voteAverage + Double(credit.voteCount) / 1_000
    }

    private static func creditPriority(_ credit: PersonCreditCrew) -> Double {
        credit.popularity + credit.voteAverage + Double(credit.voteCount) / 1_000
    }

    private static func destination(for item: PersonDetailCreditItem) -> DetailContentListDestination {
        switch item.mediaType {
        case .movie:
            return .movie(id: item.sourceID)

        case .tv:
            return .tv(seriesID: item.sourceID)

        case .unknown:
            return .none
        }
    }

    private static func roleText(
        for item: PersonDetailCreditItem,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard item.subtitle != item.mediaType.displayText(localization: localization) else {
            return nil
        }

        return BaseDisplayTextFormatter.nonEmptyText(item.subtitle)
    }
}

// MARK: - CreditCandidate

private extension PersonDetailCreditsPresentationBuilder {

    struct CreditCandidate {
        let item: PersonDetailCreditItem
        let priority: Double
    }
}
