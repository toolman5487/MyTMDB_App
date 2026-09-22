//
//  AppDelegate.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

@preconcurrency import SkeletonView
import UIKit

@main
@MainActor
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureNavigationBarAppearance()
        configureSkeletonAppearance()
        return true
    }

    private func configureNavigationBarAppearance() {
        AppAppearance.applyTransparentNavigationBarAppearance(to: UINavigationBar.appearance())
    }

    private func configureSkeletonAppearance() {
        SkeletonAppearance.default.textLineHeight = .fixed(14)
        SkeletonAppearance.default.multilineCornerRadius = 6
    }

    // MARK: - UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}
