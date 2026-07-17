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

    override init(sourceViewController: UIViewController) {
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
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
            guard let url = URL(string: "\(APIConfig.tmdbWebsiteBaseURL)/list/\(id)") else {
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
            show(UINavigationController(rootViewController: LoginViewController()), using: .fullScreen)
        }
    }

    func showList(_ route: MemberCenterListRoute) {
        show(
            MemberCenterListViewController(
                destination: route.destination,
                accountId: route.accountId,
                sessionId: route.sessionId
            ),
            using: .push
        )
    }

    private func showSettings() {
        guard let navigationController = sourceViewController?.navigationController else {
            show(MainMemberSettingViewController(), using: .push)
            return
        }

        if let existingViewController = navigationController.viewControllers.last(where: { $0 is MainMemberSettingViewController }) {
            navigationController.popToViewController(existingViewController, animated: true)
            return
        }

        show(MainMemberSettingViewController(), using: .push)
    }
}
