//
//  AccessibilityText.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/27.
//

import Foundation

// MARK: - AccessibilityText

nonisolated struct AccessibilityText: Sendable, Equatable {
    let label: String
    let value: String?
    let hint: String?

    init(
        label: String,
        value: String? = nil,
        hint: String? = nil
    ) {
        self.label = label
        self.value = value
        self.hint = hint
    }
}
