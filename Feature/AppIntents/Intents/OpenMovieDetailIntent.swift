//
//  OpenMovieDetailIntent.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import AppIntents

// MARK: - OpenMovieDetailIntent

struct OpenMovieDetailIntent: AppIntent {
    static let title: LocalizedStringResource = "開啟電影詳情"
    static let description = IntentDescription("在 CineBase 開啟指定電影詳情。")
    static let openAppWhenRun = true

    @Parameter(title: "電影")
    var movie: MovieEntity

    init() {}

    init(movie: MovieEntity) {
        self.movie = movie
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let isOpened = await AppIntentNavigator.open(.movieDetail(id: movie.id))
        let message = isOpened ? "已開啟電影「\(movie.title)」。" : "目前無法開啟電影詳情。"
        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
