//
//  MainTabBarViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainTabBarViewModel

struct MainTabBarViewModel: Sendable {

    var items: [MainTabItem] {
        MainTab.allCases.map { tab in
            MainTabItem(
                kind: tab.kind,
                title: tab.title,
                imageName: tab.imageName,
                selectedImageName: tab.selectedImageName
            )
        }
    }

    // MARK: - Tab Selection

    func selectionTransition(
        from currentIndex: Int,
        direction: MainTabNavigationDirection
    ) -> MainTabSelectionTransition? {
        let targetIndex: Int

        switch direction {
        case .previous:
            targetIndex = currentIndex - 1

        case .next:
            targetIndex = currentIndex + 1
        }

        guard items.indices.contains(currentIndex),
              items.indices.contains(targetIndex) else {
            return nil
        }

        return MainTabSelectionTransition(
            targetIndex: targetIndex,
            direction: direction
        )
    }

    func transitionDirection(
        from currentIndex: Int,
        to targetIndex: Int
    ) -> MainTabNavigationDirection? {
        guard items.indices.contains(currentIndex),
              items.indices.contains(targetIndex),
              currentIndex != targetIndex else {
            return nil
        }

        return targetIndex > currentIndex ? .next : .previous
    }
}

// MARK: - MainTabItem

struct MainTabItem: Sendable {
    let kind: MainTabKind
    let title: String
    let imageName: String
    let selectedImageName: String
}

// MARK: - MainTabNavigationDirection

enum MainTabNavigationDirection: Sendable, Equatable {
    case previous
    case next
}

// MARK: - MainTabSelectionTransition

struct MainTabSelectionTransition: Sendable, Equatable {
    let targetIndex: Int
    let direction: MainTabNavigationDirection
}

// MARK: - MainTabKind

enum MainTabKind: Sendable, Equatable {
    case home
    case movie
    case series
    case memberSetting
}

// MARK: - MainTab

private enum MainTab: CaseIterable, Sendable {
    case home
    case movie
    case series
    case memberSetting

    var kind: MainTabKind {
        switch self {
        case .home:
            return .home

        case .movie:
            return .movie

        case .series:
            return .series

        case .memberSetting:
            return .memberSetting
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

        case .memberSetting:
            return "設定"
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

        case .memberSetting:
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

        case .memberSetting:
            return "person.crop.circle.fill"
        }
    }
}
