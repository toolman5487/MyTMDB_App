//
//  ProductionCompany.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - ProductionCompany

nonisolated struct ProductionCompany: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String
}
