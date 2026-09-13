//
//  TMDBPageResponse.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - TMDBPageResponse

nonisolated struct TMDBPageResponse<Result: Decodable & Sendable>: Decodable, Sendable {
    let page: Int
    let results: [Result]
    let totalPages: Int
    let totalResults: Int

    init(
        page: Int,
        results: [Result],
        totalPages: Int,
        totalResults: Int
    ) {
        self.page = page
        self.results = results
        self.totalPages = totalPages
        self.totalResults = totalResults
    }

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
