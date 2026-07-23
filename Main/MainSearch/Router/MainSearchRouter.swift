//
//  MainSearchRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import UIKit

// MARK: - MainSearchRouting

@MainActor
protocol MainSearchRouting: AnyObject {
    func showDetail(for item: MainSearchResultItem)
}

// MARK: - MainSearchRouter

@MainActor
final class MainSearchRouter: BaseRouter, MainSearchRouting {

    // MARK: - Public Methods

    func showDetail(for item: MainSearchResultItem) {
        guard let sourceViewController else { return }

        let detailRouter = DetailRouter(sourceViewController: sourceViewController)

        switch item.mediaType {
        case .movie:
            detailRouter.showMovieDetail(movieID: item.sourceID)

        case .tv:
            detailRouter.showTVDetail(seriesID: item.sourceID)

        case .person:
            detailRouter.showPersonDetail(personID: item.sourceID)

        case .unknown:
            return
        }
    }
}
