//
//  AppIntentNavigator.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import UIKit

// MARK: - AppIntentNavigator

enum AppIntentNavigator {
    static func open(
        _ destination: AppIntentDestination,
        sessionResolver: any AppIntentSessionResolving = AppIntentSessionResolver()
    ) async -> Bool {
        switch destination {
        case .favoriteMovies, .favoriteTV:
            do {
                let context = try await sessionResolver.resolveUserAccountContext()
                return await route(destination, accountContext: context)
            } catch {
                _ = await route(.login, accountContext: nil)
                return false
            }

        case .movieDetail, .tvDetail, .login:
            return await route(destination, accountContext: nil)
        }
    }

    static func open(
        _ destination: AppIntentDestination,
        in window: UIWindow,
        sessionResolver: any AppIntentSessionResolving = AppIntentSessionResolver()
    ) async -> Bool {
        switch destination {
        case .favoriteMovies, .favoriteTV:
            do {
                let context = try await sessionResolver.resolveUserAccountContext()
                return await route(destination, accountContext: context, in: window)
            } catch {
                _ = await route(.login, accountContext: nil, in: window)
                return false
            }

        case .movieDetail, .tvDetail, .login:
            return await route(destination, accountContext: nil, in: window)
        }
    }

    @MainActor
    static func open(_ url: URL, in window: UIWindow) {
        guard let destination = AppIntentDestination(url: url) else { return }
        Task {
            _ = await open(destination, in: window)
        }
    }

    @MainActor
    private static func route(
        _ destination: AppIntentDestination,
        accountContext: MemberCenterAccountContext?
    ) -> Bool {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow) else {
            return false
        }

        return route(destination, accountContext: accountContext, in: window)
    }

    @MainActor
    private static func route(
        _ destination: AppIntentDestination,
        accountContext: MemberCenterAccountContext?,
        in window: UIWindow
    ) -> Bool {
        guard let tabBarController = window.rootViewController as? MainTabBarController else {
            return false
        }

        switch destination {
        case .favoriteMovies:
            guard let accountContext else { return false }
            tabBarController.showMemberCenterListFromIntent(
                destination: .favoriteMovies,
                accountContext: accountContext
            )

        case .favoriteTV:
            guard let accountContext else { return false }
            tabBarController.showMemberCenterListFromIntent(
                destination: .favoriteTV,
                accountContext: accountContext
            )

        case .movieDetail(let id):
            tabBarController.showMovieDetailFromIntent(movieID: id)

        case .tvDetail(let id):
            tabBarController.showTVDetailFromIntent(seriesID: id)

        case .login:
            tabBarController.showLoginFromIntent()
        }

        return true
    }
}
