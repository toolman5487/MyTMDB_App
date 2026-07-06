//
//  MainMovieListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieListRouting

@MainActor
protocol MainMovieListRouting {
    func showMovieDetail(movieID: Int)
    func showMovieDetailFromSearch(movieID: Int)
    func showGenrePageSheet(
        filters: [MainMovieGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - MainMovieListRouter

@MainActor
final class MainMovieListRouter: BaseRouter, MainMovieListRouting {

    // MARK: - Push

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        show(MovieDetailViewController(movieID: movieID), using: .push)
    }

    func showMovieDetailFromSearch(movieID: Int) {
        showMovieDetail(movieID: movieID)
    }

    // MARK: - Page Sheet

    func showGenrePageSheet(
        filters: [MainMovieGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        guard !filters.isEmpty else { return }

        let viewController = MainMovieGenrePageSheetViewController(
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
        show(viewController, using: .pageSheet(.medium))
    }
}
