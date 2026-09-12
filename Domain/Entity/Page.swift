//
//  Page.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Page

nonisolated struct Page<Element: Sendable & Equatable>: Sendable, Equatable {
    let number: Int
    let totalPages: Int
    let totalResults: Int
    let items: [Element]

    var hasNextPage: Bool {
        number < totalPages
    }

    static func empty(number: Int = 1) -> Page<Element> {
        Page(number: number, totalPages: 1, totalResults: 0, items: [])
    }
}
