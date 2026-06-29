//
//  MainTabBarItem.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainTabBarItem

enum MainTabBarItem: Int, CaseIterable, Sendable {
    case home
    case discover
    case watchlist
    case profile

    static func items(for session: AuthSession) -> [MainTabBarItem] {
        switch session {
        case .loggedOut:
            return []

        case .guest:
            return [
                .home,
                .discover,
            ]

        case .user:
            return [
                .home,
                .discover,
                .watchlist,
                .profile,
            ]
        }
    }

    var title: String {
        switch self {
        case .home:
            return "首頁"

        case .discover:
            return "探索"

        case .watchlist:
            return "片單"

        case .profile:
            return "我的"
        }
    }

    var placeholderTitle: String {
        switch self {
        case .home:
            return "電影首頁"

        case .discover:
            return "探索電影"

        case .watchlist:
            return "我的片單"

        case .profile:
            return "會員中心"
        }
    }

    var imageSystemName: String {
        switch self {
        case .home:
            return "house"

        case .discover:
            return "sparkle.magnifyingglass"

        case .watchlist:
            return "bookmark"

        case .profile:
            return "person.crop.circle"
        }
    }

    var selectedImageSystemName: String {
        switch self {
        case .home:
            return "house.fill"

        case .discover:
            return "sparkle.magnifyingglass"

        case .watchlist:
            return "bookmark.fill"

        case .profile:
            return "person.crop.circle.fill"
        }
    }
}
