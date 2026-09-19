//
//  AppInterfaceLanguageStore.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/19.
//

import Foundation

// MARK: - AppInterfaceLanguageStoring

nonisolated protocol AppInterfaceLanguageStoring: Sendable {
    func load() -> AppInterfaceLanguage
    func save(_ language: AppInterfaceLanguage)
}

// MARK: - AppInterfaceLanguageStore

nonisolated final class AppInterfaceLanguageStore: AppInterfaceLanguageStoring {

    // MARK: - Properties

    private let preferences: AppPreferencesStorage
    private let storageKey: String

    // MARK: - Initialization

    init(
        preferences: AppPreferencesStorage = .standard,
        storageKey: String = "AppInterfaceLanguage.v1"
    ) {
        self.preferences = preferences
        self.storageKey = storageKey
    }

    // MARK: - AppInterfaceLanguageStoring

    func load() -> AppInterfaceLanguage {
        preferences.performLocked { preferencesStore in
            guard let rawValue = preferencesStore.string(forKey: storageKey),
                  let language = AppInterfaceLanguage(rawValue: rawValue) else {
                return .traditionalChinese
            }
            return language
        }
    }

    func save(_ language: AppInterfaceLanguage) {
        preferences.performLocked { preferencesStore in
            preferencesStore.set(language.rawValue, forKey: storageKey)
        }
    }
}
