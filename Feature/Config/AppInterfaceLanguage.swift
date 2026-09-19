//
//  AppInterfaceLanguage.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/19.
//

import Foundation

// MARK: - AppInterfaceLanguage

nonisolated enum AppInterfaceLanguage: String, Sendable, Equatable {
    case traditionalChinese = "zh-Hant"
    case english = "en"

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var isEnglish: Bool {
        self == .english
    }

    init(isEnglish: Bool) {
        self = isEnglish ? .english : .traditionalChinese
    }
}
