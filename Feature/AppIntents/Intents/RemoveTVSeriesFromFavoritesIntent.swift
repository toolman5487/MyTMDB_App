//
//  RemoveTVSeriesFromFavoritesIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - RemoveTVSeriesFromFavoritesIntent

struct RemoveTVSeriesFromFavoritesIntent: AppIntent {
    static let title: LocalizedStringResource = "移除收藏影集"
    static let description = IntentDescription("將指定影集從 TMDB 收藏移除。")

    @Parameter(title: "影集")
    var series: TVSeriesEntity

    init() {}

    init(series: TVSeriesEntity) {
        self.series = series
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let outcome = await AppIntentFavoriteActionHandler().updateFavorite(
            mediaType: .tv,
            mediaID: series.id,
            favorite: false,
            displayTitle: series.name
        )
        return .result(dialog: IntentDialog(stringLiteral: outcome.message))
    }
}
