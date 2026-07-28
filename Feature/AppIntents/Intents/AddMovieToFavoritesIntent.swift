//
//  AddMovieToFavoritesIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - AddMovieToFavoritesIntent

struct AddMovieToFavoritesIntent: AppIntent {
    static let title: LocalizedStringResource = "收藏電影"
    static let description = IntentDescription("將指定電影加入 TMDB 收藏。")

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
            favorite: true,
            displayTitle: movie.title
        )
        return .result(dialog: IntentDialog(stringLiteral: outcome.message))
    }
}
