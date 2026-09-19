//
//  DetailRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import UIKit

// MARK: - DetailRouting

@MainActor
protocol DetailRouting {

    // MARK: Push

    func showMovieDetail(movieID: Int)
    func showTVDetail(seriesID: Int)
    func showSeasonDetail(seriesID: Int, seasonNumber: Int)
    func showEpisodeDetail(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
    func showPersonDetail(personID: Int)
    func showMediaDetail(kind: MediaKind, id: Int)
    func showContentList(_ configuration: DetailContentListConfiguration)
    func showWebVideo(url: URL, title: String?)
    func openExternalURL(_ url: URL)
    func showLogin()
    func showImagePreview(imageURLs: [URL], selectedImageURL: URL, title: String?)

    // MARK: Page Sheet

    func showRatingPageSheet(
        title: String,
        currentValue: Double?,
        defaultValue: Double,
        onSubmit: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    )
    func showYouTubeVideo(videoKey: String, title: String?)

    // MARK: Share

    func showShareSheet(for url: URL, sourceItem: UIBarButtonItem)
}

// MARK: - DetailRouter

@MainActor
final class DetailRouter: BaseRouter, DetailRouting {

    // MARK: - Properties

    private let sceneBuilder: DetailSceneBuilding

    // MARK: - Initialization

    init(
        sourceViewController: UIViewController,
        sceneBuilder: DetailSceneBuilding,
        interfaceLocalization: AppInterfaceLocalization
    ) {
        self.sceneBuilder = sceneBuilder
        super.init(
            sourceViewController: sourceViewController,
            interfaceLocalization: interfaceLocalization
        )
    }

    // MARK: - Push

    func showMovieDetail(movieID: Int) {
        guard movieID > 0 else { return }
        show(sceneBuilder.makeMovieDetailViewController(movieID: movieID), using: .push)
    }

    func showTVDetail(seriesID: Int) {
        guard seriesID > 0 else { return }
        show(sceneBuilder.makeTVDetailViewController(seriesID: seriesID), using: .push)
    }

    func showSeasonDetail(seriesID: Int, seasonNumber: Int) {
        guard seriesID > 0, seasonNumber >= 0 else { return }
        show(
            sceneBuilder.makeSeasonDetailViewController(
                seriesID: seriesID,
                seasonNumber: seasonNumber
            ),
            using: .push
        )
    }

    func showEpisodeDetail(seriesID: Int, seasonNumber: Int, episodeNumber: Int) {
        guard seriesID > 0, seasonNumber >= 0, episodeNumber > 0 else { return }
        show(
            sceneBuilder.makeEpisodeDetailViewController(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            ),
            using: .push
        )
    }

    func showPersonDetail(personID: Int) {
        guard personID > 0 else { return }
        show(sceneBuilder.makePersonDetailViewController(personID: personID), using: .push)
    }

    func showMediaDetail(kind: MediaKind, id: Int) {
        switch kind {
        case .movie:
            showMovieDetail(movieID: id)

        case .tv:
            showTVDetail(seriesID: id)
        }
    }

    func showContentList(_ configuration: DetailContentListConfiguration) {
        guard !configuration.items.isEmpty else { return }
        show(
            sceneBuilder.makeDetailContentListViewController(configuration: configuration),
            using: .push
        )
    }

    func showWebVideo(url: URL, title: String?) {
        show(
            BaseWebViewController(
                url: url,
                title: title,
                interfaceLocalization: interfaceLocalization
            ),
            using: .push
        )
    }

    func openExternalURL(_ url: URL) {
        show(
            BaseWebViewController(
                url: url,
                interfaceLocalization: interfaceLocalization
            ),
            using: .push
        )
    }

    func showLogin() {
        show(sceneBuilder.makeLoginNavigationController(context: .inApp), using: .present)
    }

    func showImagePreview(imageURLs: [URL], selectedImageURL: URL, title: String?) {
        let previewImageURLs = imageURLs.isEmpty ? [selectedImageURL] : imageURLs
        let selectedIndex = previewImageURLs.firstIndex(of: selectedImageURL) ?? 0
        let viewController = DetailImagePreviewViewController(
            imageURLs: previewImageURLs,
            selectedIndex: selectedIndex,
            title: title,
            interfaceLocalization: interfaceLocalization
        )
        show(viewController, using: .fullScreen)
    }

    // MARK: - Page Sheet

    func showRatingPageSheet(
        title: String,
        currentValue: Double?,
        defaultValue: Double,
        onSubmit: @escaping (Double) -> Void,
        onDelete: @escaping () -> Void
    ) {
        let viewController = RatingPageSheetViewController(
            title: title,
            currentValue: currentValue,
            defaultValue: defaultValue,
            interfaceLocalization: interfaceLocalization,
            onSubmit: onSubmit,
            onDelete: onDelete
        )
        let configuration = RouterPageSheetConfiguration(
            detents: [.medium()]
        )
        show(viewController, using: .pageSheet(configuration))
    }

    func showYouTubeVideo(videoKey: String, title: String?) {
        guard !videoKey.isEmpty else { return }

        let viewController = YouTubePlayerViewController(
            videoKey: videoKey,
            title: title,
            interfaceLocalization: interfaceLocalization
        )
        show(viewController, using: .pageSheet(.medium))
    }

    // MARK: - Share

    func showShareSheet(for url: URL, sourceItem: UIBarButtonItem) {
        let activityViewController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        activityViewController.popoverPresentationController?.sourceItem = sourceItem
        show(activityViewController, using: .present)
    }
}
