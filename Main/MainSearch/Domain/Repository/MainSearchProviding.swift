//
//  MainSearchProviding.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - MainSearchProviding

nonisolated protocol MainSearchProviding: Sendable {
    func dailyTrending(page: Int) async throws -> Page<MainSearchResult>

    func popularPeople(page: Int) async throws -> Page<MainSearchPopularPerson>

    func searchResults(keyword: String, page: Int) async throws -> Page<MainSearchResult>
}
