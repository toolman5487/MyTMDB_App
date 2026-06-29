//
//  MainTabBarViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainTabBarViewModel

struct MainTabBarViewModel: Sendable {

    // MARK: - Properties

    private let session: AuthSession

    var items: [MainTabItem] {
        MainTab.allCases.filter { tab in
            tab.isVisible(for: session)
        }.map { tab in
            MainTabItem(
                kind: tab.kind,
                title: tab.title,
                imageName: tab.imageName,
                selectedImageName: tab.selectedImageName
            )
        }
    }

    // MARK: - Initialization

    init(session: AuthSession) {
        self.session = session
    }
}

// MARK: - MainTabItem

struct MainTabItem: Sendable {
    let kind: MainTabKind
    let title: String
    let imageName: String
    let selectedImageName: String
}

// MARK: - MainTabKind

enum MainTabKind: Sendable {
    case home
    case movie
    case series
    case memberCenter
}

// MARK: - MainTab

private enum MainTab: CaseIterable, Sendable {
    case home
    case movie
    case series
    case memberCenter

    var kind: MainTabKind {
        switch self {
        case .home:
            return .home

        case .movie:
            return .movie

        case .series:
            return .series

        case .memberCenter:
            return .memberCenter
        }
    }

    var title: String {
        switch self {
        case .home:
            return "首頁"

        case .movie:
            return "電影"

        case .series:
            return "劇集"

        case .memberCenter:
            return "會員中心"
        }
    }

    var imageName: String {
        switch self {
        case .home:
            return "flame"

        case .movie:
            return "film.stack"

        case .series:
            return "tv"

        case .memberCenter:
            return "person.crop.circle"
        }
    }

    var selectedImageName: String {
        switch self {
        case .home:
            return "flame.fill"

        case .movie:
            return "film.stack.fill"

        case .series:
            return "tv.fill"

        case .memberCenter:
            return "person.crop.circle.fill"
        }
    }

    func isVisible(for session: AuthSession) -> Bool {
        switch (self, session) {
        case (.memberCenter, .guest):
            return false

        default:
            return true
        }
    }
}
