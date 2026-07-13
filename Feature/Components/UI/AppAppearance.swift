//
//  AppAppearance.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - AppAppearance

@MainActor
enum AppAppearance {

    static func applyTransparentNavigationBarAppearance(to navigationBar: UINavigationBar) {
        let appearance = AppFactory.NavigationBar.transparentAppearance()
        navigationBar.isTranslucent = true
        navigationBar.backgroundColor = .clear
        navigationBar.tintColor = ThemeColor.primary
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }
}
