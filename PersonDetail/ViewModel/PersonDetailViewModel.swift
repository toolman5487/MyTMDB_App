//
//  PersonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum PersonDetailViewState: Equatable {
    case idle
    case loading
    case loaded([PersonDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - PersonDetailViewModel

@MainActor
@Observable
final class PersonDetailViewModel {

    // MARK: - Properties

    private(set) var state: PersonDetailViewState = .idle

    private let service: PersonDetailServicing

    // MARK: - Initialization

    init(service: PersonDetailServicing = PersonDetailService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadPersonDetail(id: Int) async {
        guard id > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到人物",
                    message: "人物 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchPersonDetailContent(id: id)
            state = .loaded(PersonDetailSectionBuilder.makeSections(content: content))
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - PersonDetailSectionItem

nonisolated enum PersonDetailSectionItem: Sendable, Equatable {
    case biography(PersonDetailBiographySectionItem)
    case facts([PersonDetailFactItem])
    case knownFor([PersonDetailCreditItem])
    case crew([PersonDetailCreditItem])
    case profileImages([PersonDetailProfileImageItem])
    case aliases([PersonDetailAliasItem])
    case externalLinks([PersonDetailExternalLinkItem])

    var title: String? {
        switch self {
        case .biography:
            return nil

        case .facts:
            return "人物資訊"

        case .knownFor:
            return "參與作品"

        case .crew:
            return "幕後作品"

        case .profileImages:
            return "人物照片"

        case .aliases:
            return "其他名稱"

        case .externalLinks:
            return "相關連結"
        }
    }
}

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
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
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

// MARK: - PersonDetailBiographySectionItem

nonisolated struct PersonDetailBiographySectionItem: Sendable, Equatable {
    let hero: PersonDetailHeroItem
    let biography: String?
}

// MARK: - PersonDetailItem

nonisolated struct PersonDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let biography: String?
    let profileURL: URL?
    let birthdayText: String?
    let deathdayText: String?
    let placeOfBirthText: String?
    let knownForDepartmentText: String?
    let genderText: String?
    let popularityText: String?
    let homepageURL: URL?
    let imdbURL: URL?

    init(detail: PersonDetail) {
        self.id = detail.id
        self.name = detail.name
        self.biography = Self.nonEmptyText(from: detail.biography)
        self.profileURL = detail.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.birthdayText = Self.nonEmptyText(from: detail.birthday)
        self.deathdayText = Self.nonEmptyText(from: detail.deathday)
        self.placeOfBirthText = Self.nonEmptyText(from: detail.placeOfBirth)
        self.knownForDepartmentText = Self.nonEmptyText(from: detail.knownForDepartment)
        self.genderText = Self.makeGenderText(detail.gender)
        self.popularityText = detail.popularity > 0 ? String(format: "%.1f", detail.popularity) : nil
        self.homepageURL = Self.makeURL(from: detail.homepage)
        self.imdbURL = Self.makeIMDbURL(from: detail.imdbID)
    }

    private static func makeGenderText(_ gender: PersonGender) -> String? {
        switch gender {
        case .notSpecified:
            return nil

        case .female:
            return "女性"

        case .male:
            return "男性"

        case .nonBinary:
            return "非二元"

        case .unknown:
            return nil
        }
    }

    private static func nonEmptyText(from text: String?) -> String? {
        guard let text else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    private static func makeURL(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func makeIMDbURL(from imdbID: String?) -> URL? {
        guard let imdbID, !imdbID.isEmpty else { return nil }
        return URL(string: "https://www.imdb.com/name/\(imdbID)")
    }
}

// MARK: - PersonDetailHeroItem

nonisolated struct PersonDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let profileURL: URL?
    let metadataText: String?

    init(detail: PersonDetailItem) {
        self.id = detail.id
        self.name = detail.name
        self.profileURL = detail.profileURL
        let metadataValues = [
            detail.knownForDepartmentText,
            detail.birthdayText
        ].compactMap { $0 }
        self.metadataText = metadataValues.isEmpty ? nil : metadataValues.joined(separator: " · ")
    }
}

// MARK: - PersonDetailFactItem

nonisolated struct PersonDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

// MARK: - PersonDetailCreditItem

nonisolated struct PersonDetailCreditItem: Sendable, Equatable, Identifiable {
    let id: String
    let sourceID: Int
    let mediaType: PersonCreditMediaType
    let title: String
    let subtitle: String
    let dateText: String?
    let scoreText: String?
    let posterURL: URL?

    init(cast: PersonCombinedCreditCast) {
        self.id = "cast-\(cast.mediaType.idValue)-\(cast.creditID)-\(cast.id)"
        self.sourceID = cast.id
        self.mediaType = cast.mediaType
        self.title = cast.title
        self.subtitle = Self.makeSubtitle(primary: cast.character, fallback: cast.mediaType.displayText)
        self.dateText = Self.nonEmptyText(from: cast.primaryDate)
        self.scoreText = cast.voteCount > 0 ? String(format: "%.1f", cast.voteAverage) : nil
        self.posterURL = cast.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(crew: PersonCombinedCreditCrew) {
        self.id = "crew-\(crew.mediaType.idValue)-\(crew.creditID)-\(crew.id)"
        self.sourceID = crew.id
        self.mediaType = crew.mediaType
        self.title = crew.title
        self.subtitle = Self.makeSubtitle(primary: crew.job, fallback: crew.department)
        self.dateText = Self.nonEmptyText(from: crew.primaryDate)
        self.scoreText = crew.voteCount > 0 ? String(format: "%.1f", crew.voteAverage) : nil
        self.posterURL = crew.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeSubtitle(primary: String, fallback: String) -> String {
        let trimmedPrimary = primary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedPrimary.isEmpty {
            return trimmedPrimary
        }

        return fallback.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func nonEmptyText(from text: String?) -> String? {
        guard let text else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }
}

// MARK: - PersonDetailProfileImageItem

nonisolated struct PersonDetailProfileImageItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let sizeText: String

    init(image: PersonProfileImage) {
        self.id = image.filePath
        self.imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500)
        self.sizeText = image.width > 0 && image.height > 0 ? "\(image.width) x \(image.height)" : ""
    }
}

// MARK: - PersonDetailAliasItem

nonisolated struct PersonDetailAliasItem: Sendable, Equatable, Identifiable {
    let id: String
    let name: String

    init(name: String) {
        self.id = name
        self.name = name
    }
}

// MARK: - PersonDetailExternalLinkItem

nonisolated struct PersonDetailExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let url: URL
}

// MARK: - PersonCreditMediaType Presentation

private extension PersonCreditMediaType {

    var idValue: String {
        switch self {
        case .movie:
            return "movie"

        case .tv:
            return "tv"

        case .unknown(let value):
            return value
        }
    }

    var displayText: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "影集"

        case .unknown(let value):
            return value
        }
    }
}
