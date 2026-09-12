//
//  DomainError.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - DomainError

nonisolated enum DomainError: Error, Equatable {
    case invalidIdentifier(MediaKind)
}
