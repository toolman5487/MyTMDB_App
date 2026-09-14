//
//  AddTVSeriesToFavoritesIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - AddTVSeriesToFavoritesIntent

struct AddTVSeriesToFavoritesIntent: AppIntent {
    static let title: LocalizedStringResource = "收藏影集"
    static let description = IntentDescription("將指定影集加入 TMDB 收藏。")

    @Parameter(title: "影集")
    var series: TVSeriesEntity

    init() {}

    init(series: TVSeriesEntity) {
        self.series = series
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let handler = await MainActor.run {
            AppComposition().makeAppIntentFavoriteActionHandler()
        }
        let outcome = await handler.updateFavorite(
            mediaType: .tv,
            mediaID: series.id,
            favorite: true,
            displayTitle: series.name
        )
        return .result(dialog: IntentDialog(stringLiteral: outcome.message))
    }
}
