//
//  CineBaseAppShortcuts.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - CineBaseAppShortcuts

nonisolated struct CineBaseAppShortcuts: AppShortcutsProvider {
    static let shortcutTileColor: ShortcutTileColor = .navy

    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenFavoriteMoviesIntent(),
            phrases: [
                "在 \(.applicationName) 開啟收藏電影",
                "用 \(.applicationName) 打開我的收藏電影"
            ],
            shortTitle: "收藏電影",
            systemImageName: "bookmark.fill"
        )

        AppShortcut(
            intent: OpenFavoriteTVIntent(),
            phrases: [
                "在 \(.applicationName) 開啟收藏影集",
                "用 \(.applicationName) 打開我的收藏影集"
            ],
            shortTitle: "收藏影集",
            systemImageName: "bookmark.fill"
        )

        AppShortcut(
            intent: OpenMovieDetailIntent(),
            phrases: [
                "在 \(.applicationName) 開啟 \(\.$movie)",
                "用 \(.applicationName) 看 \(\.$movie)"
            ],
            shortTitle: "電影詳情",
            systemImageName: "film.fill"
        )

        AppShortcut(
            intent: OpenTVSeriesDetailIntent(),
            phrases: [
                "在 \(.applicationName) 開啟 \(\.$series)",
                "用 \(.applicationName) 看 \(\.$series)"
            ],
            shortTitle: "影集詳情",
            systemImageName: "tv.fill"
        )
    }
}
