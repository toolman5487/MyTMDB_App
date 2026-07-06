//
//  MainMovieListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieListRouting

@MainActor
protocol MainMovieListRouting: AnyObject {
    var shouldIgnoreSearchCancellation: Bool { get }

    func showMovieDetail(movieID: Int)
    func showMovieDetailFromSearch(
        movieID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    )
    func showGenrePageSheet(
        filters: [MainMovieGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    )
}

// MARK: - MainMovieListRouter

@MainActor
final class MainMovieListRouter: BaseRouter, MainMovieListRouting {

    // MARK: - Properties

    private(set) var isDismissingSearchForNavigation = false

    var shouldIgnoreSearchCancellation: Bool {
        isDismissingSearchForNavigation
    }

    // MARK: - Push

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        show(MovieDetailViewController(movieID: movieID), using: .push)
    }

    func showMovieDetailFromSearch(
        movieID: Int,
        searchController: UISearchController,
        onSearchDismissed: @escaping () -> Void
    ) {
        guard movieID > 0,
              let sourceViewController,
              let navigationController = sourceViewController.navigationController else {
            return
        }

        isDismissingSearchForNavigation = true
        searchController.searchBar.resignFirstResponder()

        let finishSearchCleanup = { [weak self] in
            guard let self else { return }

            if searchController.isActive {
                searchController.isActive = false
            }

            isDismissingSearchForNavigation = false
            onSearchDismissed()
        }

        show(MovieDetailViewController(movieID: movieID), using: .push)

        if let transitionCoordinator = navigationController.transitionCoordinator {
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] context in
                guard !context.isCancelled else {
                    self?.isDismissingSearchForNavigation = false
                    return
                }

                finishSearchCleanup()
            }
        } else {
            Task { @MainActor in
                finishSearchCleanup()
            }
        }
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
