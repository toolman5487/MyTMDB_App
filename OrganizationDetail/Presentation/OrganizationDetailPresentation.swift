//
//  OrganizationDetailPresentation.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import Foundation

// MARK: - Sections

nonisolated enum OrganizationDetailSectionItem: Sendable, Equatable {
    case hero(OrganizationDetailHeroItem)
    case overview(String)
    case facts([OrganizationDetailFactItem])
    case aliases([OrganizationDetailAliasItem])
    case logos([OrganizationDetailLogoItem])
    case homepage(OrganizationDetailLinkItem)

    var title: String? {
        switch self {
        case .hero:
            return nil

        case .overview:
            return "簡介"

        case .facts:
            return "基本資料"

        case .aliases:
            return "其他名稱"

        case .logos:
            return "標誌圖片"

        case .homepage:
            return "相關連結"
        }
    }
}

// MARK: - Presentation Models

nonisolated struct OrganizationDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let kindText: String
    let countryText: String?
    let logoURL: URL?
}

nonisolated struct OrganizationDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

nonisolated struct OrganizationDetailAliasItem: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
}

nonisolated struct OrganizationDetailLogoItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL
    let resolutionText: String?
}

nonisolated struct OrganizationDetailLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String
    let url: URL
}

// MARK: - Builder

nonisolated enum OrganizationDetailSectionBuilder {

    static func makeSections(content: OrganizationDetailContent) -> [OrganizationDetailSectionItem] {
        let detail = content.detail
        let countryText = countryName(regionCode: detail.originCountry)
        var sections: [OrganizationDetailSectionItem] = [
            .hero(
                OrganizationDetailHeroItem(
                    id: detail.id,
                    name: detail.name,
                    kindText: content.kind.displayName,
                    countryText: countryText,
                    logoURL: detail.logoPath.flatMap {
                        APIConfig.tmdbImageURL(path: $0, size: .w500)
                    }
                )
            )
        ]

        if let overview = BaseDisplayTextFormatter.nonEmptyText(detail.description) {
            sections.append(.overview(overview))
        }

        let facts = makeFacts(detail: detail, countryText: countryText)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let aliases = makeAliases(content.alternativeNames.results)
        if !aliases.isEmpty {
            sections.append(.aliases(aliases))
        }

        let logos = makeLogos(content.images.logos)
        if !logos.isEmpty {
            sections.append(.logos(logos))
        }

        if let homepage = makeHomepage(detail.homepage) {
            sections.append(.homepage(homepage))
        }

        return sections
    }

    private static func makeFacts(
        detail: OrganizationDetail,
        countryText: String?
    ) -> [OrganizationDetailFactItem] {
        [
            makeFact(title: "國家／地區", value: countryText),
            makeFact(title: "總部", value: detail.headquarters),
            makeFact(title: "母公司", value: detail.parentCompany?.name)
        ].compactMap { $0 }
    }

    private static func makeFact(
        title: String,
        value: String?
    ) -> OrganizationDetailFactItem? {
        guard let value = BaseDisplayTextFormatter.nonEmptyText(value) else { return nil }
        return OrganizationDetailFactItem(title: title, value: value)
    }

    private static func makeAliases(
        _ aliases: [OrganizationAlternativeName]
    ) -> [OrganizationDetailAliasItem] {
        var seenNames = Set<String>()

        return aliases.compactMap { alias in
            guard let name = BaseDisplayTextFormatter.nonEmptyText(alias.name) else { return nil }
            let normalizedName = name.lowercased()
            guard seenNames.insert(normalizedName).inserted else { return nil }

            return OrganizationDetailAliasItem(
                id: normalizedName,
                name: name
            )
        }
    }

    private static func makeLogos(
        _ logos: [OrganizationLogo]
    ) -> [OrganizationDetailLogoItem] {
        var seenPaths = Set<String>()

        return logos.compactMap { logo in
            guard seenPaths.insert(logo.filePath).inserted,
                  let imageURL = APIConfig.tmdbImageURL(
                    path: rasterLogoPath(logo.filePath),
                    size: .w500
                  ) else {
                return nil
            }

            return OrganizationDetailLogoItem(
                id: logo.filePath,
                imageURL: imageURL,
                resolutionText: BaseDisplayTextFormatter.resolution(
                    width: logo.width,
                    height: logo.height
                )
            )
        }
    }

    private static func rasterLogoPath(_ path: String) -> String {
        guard path.lowercased().hasSuffix(".svg") else { return path }
        return String(path.dropLast(4)) + ".png"
    }

    private static func makeHomepage(_ value: String?) -> OrganizationDetailLinkItem? {
        guard let text = BaseDisplayTextFormatter.nonEmptyText(value),
              let url = URL(string: text) else {
            return nil
        }

        return OrganizationDetailLinkItem(
            id: "homepage",
            title: "官方網站",
            value: url.host ?? text,
            url: url
        )
    }

    private static func countryName(regionCode: String?) -> String? {
        guard let regionCode = BaseDisplayTextFormatter.nonEmptyText(regionCode) else {
            return nil
        }

        return Locale(identifier: "zh_Hant_TW").localizedString(
            forRegionCode: regionCode.uppercased()
        ) ?? regionCode.uppercased()
    }
}
