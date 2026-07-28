//
//  RemoveMovieFromFavoritesIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - RemoveMovieFromFavoritesIntent

struct RemoveMovieFromFavoritesIntent: AppIntent {
    static let title: LocalizedStringResource = "移除收藏電影"
    static let description = IntentDescription("將指定電影從 TMDB 收藏移除。")

    @Parameter(title: "電影")
    var movie: MovieEntity

    init() {}

    init(movie: MovieEntity) {
        self.movie = movie
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let outcome = await AppIntentFavoriteActionHandler().updateFavorite(
            mediaType: .movie,
            mediaID: movie.id,
            favorite: false,
            displayTitle: movie.title
        )
        return .result(dialog: IntentDialog(stringLiteral: outcome.message))
    }
}
