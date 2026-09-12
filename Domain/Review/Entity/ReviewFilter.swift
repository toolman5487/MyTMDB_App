//
//  ReviewFilter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - ReviewFilter

nonisolated enum ReviewFilter: CaseIterable, Sendable, Equatable {
    case all
    case rated
    case unrated
    case latest
    case oldest
}
