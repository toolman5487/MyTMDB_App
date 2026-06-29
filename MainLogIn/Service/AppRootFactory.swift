//
//  AppRootFactory.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit

// MARK: - AppRootFactory

enum AppRootFactory {

    @MainActor
    static func makeRootViewController(for session: AuthSession) -> UIViewController {
        switch session {
        case .loggedOut:
            return UINavigationController(rootViewController: LoginViewController())

        case .guest, .user:
            return MainTabBarController(session: session)
        }
    }

    @MainActor
    static func replaceRoot(in window: UIWindow, for session: AuthSession) {
        window.rootViewController = makeRootViewController(for: session)
        window.makeKeyAndVisible()
    }
}
