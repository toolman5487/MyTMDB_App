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
    case movieCredits([PersonDetailCreditItem])
    case tvCredits([PersonDetailCreditItem])
    case profileImages([PersonDetailProfileImageItem])
    case aliases([PersonDetailAliasItem])
    case externalLinks([PersonDetailExternalLinkItem])

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .biography:
            return nil

        case .facts:
            return localization.string("person_detail.section.information", defaultValue: "Personal Information")

        case .movieCredits:
            return PersonCreditMediaType.movie.creditsTitle(localization: localization)

        case .tvCredits:
            return PersonCreditMediaType.tv.creditsTitle(localization: localization)

        case .profileImages:
            return localization.string("person_detail.section.profile_images", defaultValue: "Profile Photos")

        case .aliases:
            return localization.string("person_detail.section.aliases", defaultValue: "Also Known As")

        case .externalLinks:
            return localization.string("detail.section.external_links", defaultValue: "Related Links")
        }
    }

    var creditsMediaType: PersonCreditMediaType? {
        switch self {
        case .movieCredits:
            return .movie

        case .tvCredits:
            return .tv

        case .biography, .facts, .profileImages, .aliases, .externalLinks:
            return nil
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

    init(detail: Person, localization: AppInterfaceLocalization) {
        self.id = detail.id
        self.name = BaseDisplayTextFormatter.text(
            detail.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.biography = BaseDisplayTextFormatter.nonEmptyText(detail.biography)
        self.profileURL = detail.profilePath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w500)
        }
        self.birthdayText = BaseDisplayTextFormatter.isoDayText(from: detail.birthday)
        self.deathdayText = BaseDisplayTextFormatter.isoDayText(from: detail.deathday)
        self.placeOfBirthText = BaseDisplayTextFormatter.nonEmptyText(detail.placeOfBirth)
        self.knownForDepartmentText = BaseFormatter.CrewJobDisplayMapper.departmentText(
            detail.knownForDepartment,
            localization: localization
        )
        self.genderText = Self.makeGenderText(detail.gender, localization: localization)
        self.popularityText = BaseDisplayTextFormatter.positiveDecimal(detail.popularity)
        self.homepageURL = detail.homepage
        self.imdbURL = Self.makeIMDbURL(from: detail.imdbID)
    }

    private static func makeGenderText(
        _ gender: PersonGender,
        localization: AppInterfaceLocalization
    ) -> String? {
        switch gender {
        case .notSpecified:
            return nil

        case .female:
            return localization.string("person_detail.gender.female", defaultValue: "Female")

        case .male:
            return localization.string("person_detail.gender.male", defaultValue: "Male")

        case .nonBinary:
            return localization.string("person_detail.gender.non_binary", defaultValue: "Non-binary")

        case .unknown:
            return nil
        }
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

    var mediaKind: MediaKind? {
        switch mediaType {
        case .movie:
            return .movie

        case .tv:
            return .tv

        case .unknown:
            return nil
        }
    }
    let title: String
    let subtitle: String
    let dateText: String?
    let scoreText: String?
    let posterURL: URL?

    init(
        cast: PersonCreditCast,
        mediaType: PersonCreditMediaType? = nil,
        localization: AppInterfaceLocalization
    ) {
        let resolvedMediaType = mediaType ?? cast.mediaType
        self.id = "cast-\(resolvedMediaType.idValue)-\(cast.creditID)-\(cast.id)"
        self.sourceID = cast.id
        self.mediaType = resolvedMediaType
        self.title = BaseDisplayTextFormatter.text(
            cast.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.subtitle = Self.makeSubtitle(
            primary: cast.character,
            fallback: resolvedMediaType.displayText(localization: localization)
        )
        self.dateText = BaseDisplayTextFormatter.isoDayText(from: cast.primaryDate)
        self.scoreText = BaseDisplayTextFormatter.score(cast.voteAverage, voteCount: cast.voteCount)
        self.posterURL = cast.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }

    init(
        crew: PersonCreditCrew,
        mediaType: PersonCreditMediaType? = nil,
        localization: AppInterfaceLocalization
    ) {
        let resolvedMediaType = mediaType ?? crew.mediaType
        self.id = "crew-\(resolvedMediaType.idValue)-\(crew.creditID)-\(crew.id)"
        self.sourceID = crew.id
        self.mediaType = resolvedMediaType
        self.title = BaseDisplayTextFormatter.text(
            crew.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.subtitle = BaseFormatter.CrewJobDisplayMapper.displayText(
            job: crew.job,
            department: crew.department,
            localization: localization
        ) ?? ""
        self.dateText = BaseDisplayTextFormatter.isoDayText(from: crew.primaryDate)
        self.scoreText = BaseDisplayTextFormatter.score(crew.voteAverage, voteCount: crew.voteCount)
        self.posterURL = crew.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
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
        self.imageURL = TMDBResourceURL.image(path: image.filePath, size: .w500)
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

    func displayText(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return MediaKind.movie.displayName(localization: localization)

        case .tv:
            return MediaKind.tv.displayName(localization: localization)

        case .unknown(let value):
            return value
        }
    }

    func creditsTitle(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .movie:
            return localization.string("person_detail.credits.movie.title", defaultValue: "Movie Credits")

        case .tv:
            return localization.string("person_detail.credits.tv.title", defaultValue: "TV Credits")

        case .unknown:
            return localization.string("person_detail.credits.other.title", defaultValue: "Credits")
        }
    }
}
