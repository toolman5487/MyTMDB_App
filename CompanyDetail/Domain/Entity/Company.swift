//
//  Company.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - Company

nonisolated struct Company: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let headquarters: String?
    let homepage: URL?
    let logoPath: String?
    let originCountry: String?
    let parentCompany: CompanyReference?
}

// MARK: - CompanyReference

nonisolated struct CompanyReference: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
}
