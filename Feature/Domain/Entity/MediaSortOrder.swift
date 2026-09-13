//
//  MediaSortOrder.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaSortOrder

nonisolated enum MediaSortOrder: CaseIterable, Sendable, Hashable {
    case popularity
    case ratingHighToLow
    case ratingLowToHigh
    case newestDate
    case oldestDate
    case titleAscending
    case titleDescending
}
