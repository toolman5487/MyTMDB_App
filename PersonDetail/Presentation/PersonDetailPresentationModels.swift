//
//  PersonDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/22.
//

import Foundation

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
        self.biography = BaseDisplayTextFormatter.nonEmptyText(detail.biography)
        self.profileURL = detail.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.birthdayText = BaseDisplayTextFormatter.nonEmptyText(detail.birthday)
        self.deathdayText = BaseDisplayTextFormatter.nonEmptyText(detail.deathday)
        self.placeOfBirthText = BaseDisplayTextFormatter.nonEmptyText(detail.placeOfBirth)
        self.knownForDepartmentText = BaseDisplayTextFormatter.nonEmptyText(detail.knownForDepartment)
        self.genderText = Self.makeGenderText(detail.gender)
        self.popularityText = BaseDisplayTextFormatter.positiveDecimal(detail.popularity)
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
        self.metadataText = BaseDisplayTextFormatter.metadata([
            detail.knownForDepartmentText,
            detail.birthdayText
        ])
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
        self.dateText = BaseDisplayTextFormatter.nonEmptyText(cast.primaryDate)
        self.scoreText = BaseDisplayTextFormatter.score(cast.voteAverage, voteCount: cast.voteCount)
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
        self.dateText = BaseDisplayTextFormatter.nonEmptyText(crew.primaryDate)
        self.scoreText = BaseDisplayTextFormatter.score(crew.voteAverage, voteCount: crew.voteCount)
        self.posterURL = crew.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    private static func makeSubtitle(primary: String, fallback: String) -> String {
        BaseDisplayTextFormatter.firstNonEmptyText([primary, fallback]) ?? ""
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
        self.sizeText = BaseDisplayTextFormatter.resolutionText(
            width: image.width,
            height: image.height
        )
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

extension PersonCreditMediaType {

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
