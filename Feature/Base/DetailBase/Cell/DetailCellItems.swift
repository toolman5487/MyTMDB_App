//
//  DetailCellItems.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import Foundation

// MARK: - DetailSectionPreviewLimit

nonisolated enum DetailSectionPreviewLimit {
    static let itemCount = 10
}

// MARK: - DetailFactItem

nonisolated struct DetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

// MARK: - DetailImageTitleItem

nonisolated struct DetailImageTitleItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let title: String
    let subtitle: String?
}

// MARK: - DetailExternalLinkItem

nonisolated struct DetailExternalLinkItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let url: URL
}
