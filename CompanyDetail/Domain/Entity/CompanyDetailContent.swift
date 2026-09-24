//
//  CompanyDetailContent.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailContent

nonisolated struct CompanyDetailContent: Sendable, Equatable {
    let detail: Company
    let alternativeNames: [CompanyAlternativeName]
    let images: CompanyImages
    let movies: Page<MediaSummary>
    let tvShows: Page<MediaSummary>
}
