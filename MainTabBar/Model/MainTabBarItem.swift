//
//  MainTabBarItem.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

// MARK: - MainTabBarItem

enum MainTabBarItem: Int, CaseIterable, Sendable {
    case home
    case profile

    static func items(for session: AuthSession) -> [MainTabBarItem] {
        switch session {
        case .loggedOut:
            return []

        case .guest, .user:
            return [.home, .profile]
        }
    }

    var title: String {
        switch self {
        case .home:
            return "首頁"

        case .profile:
            return "個人中心"
        }
    }

    var imageSystemName: String {
        switch self {
        case .home:
            return "house"

        case .profile:
            return "person.crop.circle"
        }
    }

    var selectedImageSystemName: String {
        switch self {
        case .home:
            return "house.fill"

        case .profile:
            return "person.crop.circle.fill"
        }
    }

    @MainActor
    func makeViewController(session: AuthSession) -> MainBaseViewController {
        switch self {
        case .home:
            return MainHomeViewController()

        case .profile:
            return MainMyAccountViewController(session: session)
        }
    }
}
