//
//  DetailContentListRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import UIKit

// MARK: - DetailContentListRouting

@MainActor
protocol DetailContentListRouting: AnyObject {
    func showDestination(
        _ destination: DetailContentListDestination,
        configuration: DetailContentListConfiguration
    )
}

// MARK: - DetailContentListRouter

@MainActor
final class DetailContentListRouter: DetailContentListRouting {

    private let detailRouter: DetailRouter

    init(sourceViewController: UIViewController) {
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
    }

    func showDestination(
        _ destination: DetailContentListDestination,
        configuration: DetailContentListConfiguration
    ) {
        switch destination {
        case .movie(let id):
            detailRouter.showMovieDetail(movieID: id)

        case .tv(let seriesID):
            detailRouter.showTVDetail(seriesID: seriesID)

        case .person(let id):
            detailRouter.showPersonDetail(personID: id)

        case .youtube(let videoKey, let title):
            detailRouter.showYouTubeVideo(videoKey: videoKey, title: title)

        case .webVideo(let url, let title):
            detailRouter.showWebVideo(url: url, title: title)

        case .image(let url):
            let imageURLs = configuration.items.compactMap { item -> URL? in
                guard case .image(let imageURL) = item.destination else { return nil }
                return imageURL
            }
            detailRouter.showImagePreview(
                imageURLs: imageURLs,
                selectedImageURL: url,
                title: configuration.title
            )

        case .none:
            return
        }
    }
}
