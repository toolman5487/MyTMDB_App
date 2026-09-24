//
//  CompanyMetadata.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyAlternativeName

nonisolated struct CompanyAlternativeName: Sendable, Equatable {
    let name: String
    let type: String?
}

// MARK: - CompanyImages

nonisolated struct CompanyImages: Sendable, Equatable, Identifiable {
    let id: Int
    let logos: [CompanyLogo]

    static func empty(id: Int) -> CompanyImages {
        CompanyImages(id: id, logos: [])
    }
}

// MARK: - CompanyLogo

nonisolated struct CompanyLogo: Sendable, Equatable {
    let filePath: String
    let aspectRatio: Double
    let width: Int
    let height: Int
    let voteAverage: Double
    let voteCount: Int

    var isVectorFormat: Bool {
        filePath.lowercased().hasSuffix(".svg")
    }
}
