//
//  MediaKind.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MediaKind

nonisolated enum MediaKind: String, CaseIterable, Codable, Sendable, Equatable {
    case movie
    case tv
}
