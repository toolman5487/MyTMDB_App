//
//  OrganizationDetailModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import Foundation

// MARK: - OrganizationKind

nonisolated enum OrganizationKind: Sendable, Equatable {
    case company
    case network

    var displayName: String {
        switch self {
        case .company:
            return "製作公司"

        case .network:
            return "電視網"
        }
    }

    func detailPath(id: Int) -> String {
        switch self {
        case .company:
            return APIConfig.Company.detail(id: id)

        case .network:
            return APIConfig.Network.detail(id: id)
        }
    }

    func alternativeNamesPath(id: Int) -> String {
        switch self {
        case .company:
            return APIConfig.Company.alternativeNames(id: id)

        case .network:
            return APIConfig.Network.alternativeNames(id: id)
        }
    }

    func imagesPath(id: Int) -> String {
        switch self {
        case .company:
            return APIConfig.Company.images(id: id)

        case .network:
            return APIConfig.Network.images(id: id)
        }
    }
}

// MARK: - Content

nonisolated struct OrganizationDetailContent: Sendable, Equatable {
    let kind: OrganizationKind
    let detail: OrganizationDetail
    let alternativeNames: OrganizationAlternativeNamesResponse
    let images: OrganizationImagesResponse
}

// MARK: - Detail

nonisolated struct OrganizationDetail: Decodable, Sendable, Equatable, Identifiable {
    let description: String?
    let headquarters: String?
    let homepage: String?
    let id: Int
    let logoPath: String?
    let name: String
    let originCountry: String?
    let parentCompany: OrganizationParentCompany?

    enum CodingKeys: String, CodingKey {
        case description
        case headquarters
        case homepage
        case id
        case logoPath = "logo_path"
        case name
        case originCountry = "origin_country"
        case parentCompany = "parent_company"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.headquarters = try container.decodeIfPresent(String.self, forKey: .headquarters)
        self.homepage = try container.decodeIfPresent(String.self, forKey: .homepage)
        self.id = try container.decode(Int.self, forKey: .id)
        self.logoPath = try container.decodeIfPresent(String.self, forKey: .logoPath)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "未命名"
        self.originCountry = try container.decodeIfPresent(String.self, forKey: .originCountry)
        self.parentCompany = try container.decodeIfPresent(
            OrganizationParentCompany.self,
            forKey: .parentCompany
        )
    }
}

nonisolated struct OrganizationParentCompany: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let logoPath: String?
    let name: String

    enum CodingKeys: String, CodingKey {
        case id
        case logoPath = "logo_path"
        case name
    }
}

// MARK: - Alternative Names

nonisolated struct OrganizationAlternativeNamesResponse: Decodable, Sendable, Equatable {
    let id: Int
    let results: [OrganizationAlternativeName]

    init(id: Int, results: [OrganizationAlternativeName] = []) {
        self.id = id
        self.results = results
    }

    enum CodingKeys: String, CodingKey {
        case id
        case results
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.results = try container.decodeIfPresent(
            [OrganizationAlternativeName].self,
            forKey: .results
        ) ?? []
    }
}

nonisolated struct OrganizationAlternativeName: Decodable, Sendable, Equatable {
    let name: String
    let type: String?
}

// MARK: - Images

nonisolated struct OrganizationImagesResponse: Decodable, Sendable, Equatable {
    let id: Int
    let logos: [OrganizationLogo]

    init(id: Int, logos: [OrganizationLogo] = []) {
        self.id = id
        self.logos = logos
    }

    enum CodingKeys: String, CodingKey {
        case id
        case logos
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.logos = try container.decodeIfPresent([OrganizationLogo].self, forKey: .logos) ?? []
    }
}

nonisolated struct OrganizationLogo: Decodable, Sendable, Equatable {
    let aspectRatio: Double
    let filePath: String
    let fileType: String?
    let height: Int
    let width: Int

    enum CodingKeys: String, CodingKey {
        case aspectRatio = "aspect_ratio"
        case filePath = "file_path"
        case fileType = "file_type"
        case height
        case width
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.aspectRatio = try container.decodeIfPresent(Double.self, forKey: .aspectRatio) ?? 1
        self.filePath = try container.decode(String.self, forKey: .filePath)
        self.fileType = try container.decodeIfPresent(String.self, forKey: .fileType)
        self.height = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
        self.width = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
    }
}
