//
//  MemberCenterRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MemberCenterRouting

@MainActor
protocol MemberCenterRouting: AnyObject {
    func showDetail(for item: MemberCenterListItem)
    func showProfileAction(_ action: MemberCenterProfileAction)
    func showList(_ route: MemberCenterListRoute)
}

// MARK: - MemberCenterRouter

@MainActor
final class MemberCenterRouter: BaseRouter, MemberCenterRouting {

    private let detailRouter: DetailRouter
    private let sceneBuilder: MemberCenterSceneBuilding

    init(
        sourceViewController: UIViewController,
        sceneBuilder: MemberCenterSceneBuilding
    ) {
        self.sceneBuilder = sceneBuilder
        self.detailRouter = DetailRouter(
            sourceViewController: sourceViewController,
            sceneBuilder: sceneBuilder
        )
        super.init(sourceViewController: sourceViewController)
    }

    func showDetail(for item: MemberCenterListItem) {
        switch item.detailTarget {
        case .movie(let id):
            detailRouter.showMovieDetail(movieID: id)

        case .tv(let id):
            detailRouter.showTVDetail(seriesID: id)

        case .episode(let seriesID, let seasonNumber, let episodeNumber):
            detailRouter.showEpisodeDetail(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )

        case .list(let id):
            guard let url = URL(string: "\(TMDBResourceURL.websiteBaseURL)/list/\(id)") else {
                return
            }

            detailRouter.openExternalURL(url)
        }
    }

    func showProfileAction(_ action: MemberCenterProfileAction) {
        switch action {
        case .settings:
            showSettings()

        case .login:
            detailRouter.showLogin()
        }
    }

    func showList(_ route: MemberCenterListRoute) {
        show(
            sceneBuilder.makeMemberCenterListViewController(
                destination: route.destination,
                accountID: route.accountId,
                sessionID: route.sessionId
            ),
            using: .push
        )
    }

    private func showSettings() {
        guard let navigationController = sourceViewController?.navigationController else {
            show(sceneBuilder.makeMainMemberSettingViewController(), using: .push)
            return
        }

        if let existingViewController = navigationController.viewControllers.last(where: { $0 is MainMemberSettingViewController }) {
            navigationController.popToViewController(existingViewController, animated: true)
            return
        }

        show(sceneBuilder.makeMainMemberSettingViewController(), using: .push)
    }
}
