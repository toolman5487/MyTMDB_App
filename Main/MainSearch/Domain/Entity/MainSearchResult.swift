//
//  MainSearchResult.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - MainSearchMediaType

nonisolated enum MainSearchMediaType: String, Sendable, Equatable {
    case movie
    case tv
    case person
    case company
}

// MARK: - MainSearchResult

nonisolated struct MainSearchResult: Sendable, Equatable, Identifiable {
    let id: Int
    let mediaType: MainSearchMediaType
    let title: String
    let overview: String
    let posterPath: String?
    let profilePath: String?
    let primaryDate: CalendarDay?
    let voteAverage: Double
    let voteCount: Int
    let popularity: Double
    let knownForDepartment: String?
}

// MARK: - MainSearchPopularPerson

nonisolated struct MainSearchPopularPerson: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let profilePath: String?
    let knownForDepartment: String?
    let popularity: Double
}

// MARK: - MainSearchCompanyResult

nonisolated struct MainSearchCompanyResult: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let originCountry: String?
}

// MARK: - MainSearchDiscovery

nonisolated struct MainSearchDiscovery: Sendable, Equatable {
    let trending: Page<MainSearchResult>
    let popularPeople: [MainSearchPopularPerson]
}
