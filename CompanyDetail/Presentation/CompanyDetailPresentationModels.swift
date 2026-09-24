//
//  CompanyDetailPresentationModels.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailSectionItem

nonisolated enum CompanyDetailSectionItem: Sendable, Equatable {
    case header(CompanyDetailHeaderSectionItem)
    case facts([CompanyDetailFactItem])
    case movies([CompanyDetailMediaItem])
    case tvShows([CompanyDetailMediaItem])
    case logos([CompanyDetailLogoItem])
    case alternativeNames([CompanyDetailAlternativeNameItem])
    case externalLinks([CompanyDetailExternalLinkItem])

    func title(localization: AppInterfaceLocalization) -> String? {
        switch self {
        case .header:
            return nil

        case .facts:
            return localization.string("company_detail.section.information", defaultValue: "Company Information")

        case .movies:
            return localization.string("company_detail.section.movies", defaultValue: "Movies")

        case .tvShows:
            return localization.string("company_detail.section.tv_shows", defaultValue: "TV Shows")

        case .logos:
            return localization.string("company_detail.section.logos", defaultValue: "Logos")

        case .alternativeNames:
            return localization.string("company_detail.section.alternative_names", defaultValue: "Also Known As")

        case .externalLinks:
            return localization.string("detail.section.external_links", defaultValue: "Related Links")
        }
    }

    var mediaKindForContentList: MediaKind? {
        switch self {
        case .movies:
            return .movie

        case .tvShows:
            return .tv

        case .header, .facts, .logos, .alternativeNames, .externalLinks:
            return nil
        }
    }
}

// MARK: - CompanyDetailHeaderSectionItem

nonisolated struct CompanyDetailHeaderSectionItem: Sendable, Equatable {
    let hero: CompanyDetailHeroItem
    let description: String?
}

// MARK: - CompanyDetailItem

nonisolated struct CompanyDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let logoURL: URL?
    let headquartersText: String?
    let originCountryText: String?
    let parentCompanyText: String?
    let homepageURL: URL?

    init(detail: Company, localization: AppInterfaceLocalization) {
        self.id = detail.id
        self.name = BaseDisplayTextFormatter.text(
            detail.name,
            fallback: localization.string("common.fallback.unnamed", defaultValue: "Unnamed")
        )
        self.description = BaseDisplayTextFormatter.nonEmptyText(detail.description)
        self.logoURL = Self.makeLogoURL(path: detail.logoPath)
        self.headquartersText = BaseDisplayTextFormatter.nonEmptyText(detail.headquarters)
        self.originCountryText = Self.makeOriginCountryText(detail.originCountry, localization: localization)
        self.parentCompanyText = BaseDisplayTextFormatter.nonEmptyText(detail.parentCompany?.name)
        self.homepageURL = detail.homepage
    }

    private static func makeLogoURL(path: String?) -> URL? {
        guard let path, !path.isEmpty, !path.lowercased().hasSuffix(".svg") else { return nil }
        return TMDBResourceURL.image(path: path, size: .w500)
    }

    private static func makeOriginCountryText(
        _ countryCode: String?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let countryCode, !countryCode.isEmpty else { return nil }
        return localization.language.locale.localizedString(forRegionCode: countryCode) ?? countryCode
    }
}

// MARK: - CompanyDetailHeroItem

nonisolated struct CompanyDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoURL: URL?
    let metadataText: String?

    init(detail: CompanyDetailItem) {
        self.id = detail.id
        self.name = detail.name
        self.logoURL = detail.logoURL
        self.metadataText = BaseDisplayTextFormatter.metadata([
            detail.originCountryText,
            detail.headquartersText
        ])
    }
}

// MARK: - CompanyDetailFactItem

nonisolated struct CompanyDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

// MARK: - CompanyDetailMediaItem

nonisolated struct CompanyDetailMediaItem: Sendable, Equatable, Identifiable {
    let id: String
    let sourceID: Int
    let mediaKind: MediaKind
    let title: String
    let dateText: String?
    let scoreText: String?
    let posterURL: URL?

    init(
        summary: MediaSummary,
        mediaKind: MediaKind,
        localization: AppInterfaceLocalization
    ) {
        self.id = "\(mediaKind.rawValue)-\(summary.id)"
        self.sourceID = summary.id
        self.mediaKind = mediaKind
        self.title = BaseDisplayTextFormatter.text(
            summary.title,
            fallback: localization.string("common.fallback.untitled", defaultValue: "Untitled")
        )
        self.dateText = BaseDisplayTextFormatter.isoDayText(from: summary.releaseDate)
        self.scoreText = BaseDisplayTextFormatter.score(summary.voteAverage, voteCount: summary.voteCount)
        self.posterURL = summary.posterPath.flatMap {
            TMDBResourceURL.image(path: $0, size: .w185)
        }
    }
}

// MARK: - CompanyDetailLogoItem

nonisolated struct CompanyDetailLogoItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let sizeText: String

    init(logo: CompanyLogo) {
        self.id = logo.filePath
        self.imageURL = TMDBResourceURL.image(path: logo.filePath, size: .w500)
        self.sizeText = BaseDisplayTextFormatter.resolutionText(width: logo.width, height: logo.height)
    }
}

// MARK: - CompanyDetailAlternativeNameItem

nonisolated struct CompanyDetailAlternativeNameItem: Sendable, Equatable, Identifiable {
    let id: String
    let name: String

    init(alternativeName: CompanyAlternativeName) {
        self.id = alternativeName.name
        self.name = alternativeName.name
    }
}

// MARK: - CompanyDetailExternalLinkItem

nonisolated struct CompanyDetailExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let url: URL
}

// MARK: - CompanyDetailContentListResult

nonisolated struct CompanyDetailContentListResult: Sendable {
    let configuration: DetailContentListConfiguration
    let pageProvider: (any DetailContentListPageProviding)?
}
