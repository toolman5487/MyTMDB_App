//
//  BaseFilterHeaderItem.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import Foundation

// MARK: - BaseFilterHeaderItem

nonisolated struct BaseFilterHeaderItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let isSelected: Bool

    init(
        id: String,
        title: String,
        isSelected: Bool
    ) {
        self.id = id
        self.title = SimplifiedChineseTextMapper.traditionalChinese(from: title)
        self.isSelected = isSelected
    }
}
