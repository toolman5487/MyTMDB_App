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
        credits: PersonCombinedCreditsResponse,
        mediaType: PersonCreditMediaType
    ) -> [PersonDetailCreditItem] {
        Array(
            makeItems(
                credits: credits,
                mediaType: mediaType,
                allowsUnknownMediaType: false
            )
                .prefix(DetailSectionPreviewLimit.itemCount)
        )
    }

    static func makeContentListConfiguration(
        credits: PersonCombinedCreditsResponse,
        mediaType: PersonCreditMediaType
    ) -> DetailContentListConfiguration {
        let title = mediaType.listTitle
        let items = makeItems(
            credits: credits,
            mediaType: mediaType,
            allowsUnknownMediaType: true
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
                        roleText(for: item),
                        BaseDisplayTextFormatter.ratingText(item.scoreText)
                    ]),
                    destination: destination(for: item)
                )
            }
        )
    }

    private static func makeItems(
        credits: PersonCombinedCreditsResponse,
        mediaType: PersonCreditMediaType,
        allowsUnknownMediaType: Bool
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
                    item: PersonDetailCreditItem(cast: $0, mediaType: mediaType),
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
                    item: PersonDetailCreditItem(crew: $0, mediaType: mediaType),
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

    private static func creditPriority(_ credit: PersonCombinedCreditCast) -> Double {
        credit.popularity + credit.voteAverage + Double(credit.voteCount) / 1_000
    }

    private static func creditPriority(_ credit: PersonCombinedCreditCrew) -> Double {
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

    private static func roleText(for item: PersonDetailCreditItem) -> String? {
        guard item.subtitle != item.mediaType.displayText else {
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

// MARK: - PersonCreditMediaType

private extension PersonCreditMediaType {

    var listTitle: String {
        switch self {
        case .movie:
            return "電影作品"

        case .tv:
            return "劇集作品"

        case .unknown:
            return "作品"
        }
    }
}
