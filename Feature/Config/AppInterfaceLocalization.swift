//
//  AppInterfaceLocalization.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/19.
//

import Foundation

// MARK: - AppInterfaceLocalization

nonisolated struct AppInterfaceLocalization: Sendable, Equatable {
    let language: AppInterfaceLanguage

    static let traditionalChinese = AppInterfaceLocalization(language: .traditionalChinese)

    func string(
        _ key: StaticString,
        defaultValue: String
    ) -> String {
        Bundle.main.localizedString(
            forKey: key.description,
            value: defaultValue,
            table: nil,
            localizations: [language.locale.language]
        )
    }

    func formatted(
        _ key: StaticString,
        defaultValue: String,
        _ arguments: CVarArg...
    ) -> String {
        String(
            format: string(key, defaultValue: defaultValue),
            locale: language.locale,
            arguments: arguments
        )
    }
}
