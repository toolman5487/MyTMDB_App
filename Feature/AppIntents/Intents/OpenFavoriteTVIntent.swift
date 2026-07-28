//
//  OpenFavoriteTVIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - OpenFavoriteTVIntent

struct OpenFavoriteTVIntent: AppIntent {
    static let title: LocalizedStringResource = "開啟收藏影集"
    static let description = IntentDescription("在 CineBase 開啟 TMDB 帳號的收藏影集列表。")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isOpened = await AppIntentNavigator.open(.favoriteTV)
        let message = isOpened ? "已開啟收藏影集。" : "需要登入 TMDB 帳號後才能開啟收藏影集。"
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
