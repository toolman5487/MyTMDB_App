//
//  CompanyDetailDTO.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailDTO

nonisolated struct CompanyDetailDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let description: String?
    let headquarters: String?
    let homepage: String?
    let logoPath: String?
    let originCountry: String?
    let parentCompany: CompanyReferenceDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case headquarters
        case homepage
        case logoPath = "logo_path"
        case originCountry = "origin_country"
        case parentCompany = "parent_company"
    }
}

// MARK: - CompanyReferenceDTO

nonisolated struct CompanyReferenceDTO: Decodable, Sendable {
    let id: Int
    let name: String?
    let logoPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case logoPath = "logo_path"
    }
}

// MARK: - CompanyAlternativeNamesResponseDTO

nonisolated struct CompanyAlternativeNamesResponseDTO: Decodable, Sendable {
    let id: Int
    let results: [CompanyAlternativeNameDTO]
}

// MARK: - CompanyAlternativeNameDTO

nonisolated struct CompanyAlternativeNameDTO: Decodable, Sendable {
    let name: String?
    let type: String?
}

// MARK: - CompanyImagesDTO

nonisolated struct CompanyImagesDTO: Decodable, Sendable {
    let id: Int
    let logos: [CompanyLogoDTO]
}

// MARK: - CompanyLogoDTO

nonisolated struct CompanyLogoDTO: Decodable, Sendable {
    let filePath: String?
    let aspectRatio: Double?
    let width: Int?
    let height: Int?
    let voteAverage: Double?
    let voteCount: Int?

    enum CodingKeys: String, CodingKey {
        case filePath = "file_path"
        case aspectRatio = "aspect_ratio"
        case width
        case height
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
}
