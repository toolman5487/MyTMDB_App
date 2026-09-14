//
//  Genre.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - Genre

nonisolated struct Genre: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}
