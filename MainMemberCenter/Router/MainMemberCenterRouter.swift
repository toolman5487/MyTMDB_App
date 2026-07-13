//
//  MainMemberCenterRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import UIKit

// MARK: - MainMemberCenterRouting

@MainActor
protocol MainMemberCenterRouting: AnyObject {
    func showDetail(for item: MainMemberCenterListItem)
    func showSettings()
    func showLogin()
    func showList(
        for destination: MainMemberCenterDestination,
        accountId: Int,
        sessionId: String
    )
}

// MARK: - MainMemberCenterRouter

@MainActor
final class MainMemberCenterRouter: BaseRouter, MainMemberCenterRouting {

    private let detailRouter: DetailRouter

    override init(sourceViewController: UIViewController) {
        self.detailRouter = DetailRouter(sourceViewController: sourceViewController)
        super.init(sourceViewController: sourceViewController)
    }

    func showDetail(for item: MainMemberCenterListItem) {
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

    func showSettings() {
        show(MemberSettingViewController(), using: .push)
    }

    func showLogin() {
        show(UINavigationController(rootViewController: LoginViewController()), using: .fullScreen)
    }

    func showList(
        for destination: MainMemberCenterDestination,
        accountId: Int,
        sessionId: String
    ) {
        show(
            MainMemberCenterListViewController(
                destination: destination,
                accountId: accountId,
                sessionId: sessionId
            ),
            using: .push
        )
    }
}
