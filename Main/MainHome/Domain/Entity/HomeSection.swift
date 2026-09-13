//
//  HomeSection.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - HomeSection

nonisolated struct HomeSection: Sendable, Equatable {
    let category: HomeCategory
    let totalResults: Int
    let items: [MediaSummary]
}
