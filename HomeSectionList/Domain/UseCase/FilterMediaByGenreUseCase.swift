//
//  FilterMediaByGenreUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - FilterMediaByGenreUseCase

nonisolated protocol FilterMediaByGenreUseCase: Sendable {
    func callAsFunction(_ items: [MediaSummary], genreID: Int) -> [MediaSummary]
}

// MARK: - DefaultFilterMediaByGenreUseCase

nonisolated struct DefaultFilterMediaByGenreUseCase: FilterMediaByGenreUseCase {

    func callAsFunction(_ items: [MediaSummary], genreID: Int) -> [MediaSummary] {
        guard genreID != HomeGenreFilterID.all else { return items }

        return items.filter { $0.genreIDs.contains(genreID) }
    }
}
