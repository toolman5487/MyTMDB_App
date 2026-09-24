//
//  CompanyDetailProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailProviding

nonisolated protocol CompanyDetailProviding: Sendable {
    func company(id: Int) async throws -> Company
    func alternativeNames(companyID: Int) async throws -> [CompanyAlternativeName]
    func images(companyID: Int) async throws -> CompanyImages
    func movies(companyID: Int, page: Int) async throws -> Page<MediaSummary>
    func tvShows(companyID: Int, page: Int) async throws -> Page<MediaSummary>
}
