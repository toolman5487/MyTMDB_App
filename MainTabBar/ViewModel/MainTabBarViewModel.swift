//
//  MainTabBarViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation

// MARK: - MainTabBarViewModel

struct MainTabBarViewModel: Sendable {

    private let localization: AppInterfaceLocalization

    init(localization: AppInterfaceLocalization) {
        self.localization = localization
    }

    var items: [MainTabItem] {
        MainTab.allCases.map { tab in
            MainTabItem(
                kind: tab.kind,
                title: tab.title(localization: localization),
                imageName: tab.imageName,
                selectedImageName: tab.selectedImageName,
                accessibilityText: tab.accessibilityText(localization: localization)
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

    func accessibilitySelectionValue(isSelected: Bool) -> String {
        if isSelected {
            return localization.string(
                "common.accessibility.selected",
                defaultValue: "Selected"
            )
        }

        return localization.string(
            "common.accessibility.not_selected",
            defaultValue: "Not selected"
        )
    }
}

// MARK: - MainTabItem

struct MainTabItem: Sendable {
    let kind: MainTabKind
    let title: String
    let imageName: String
    let selectedImageName: String
    let accessibilityText: AccessibilityText
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
    case search
    case movie
    case series
    case memberSetting
}

// MARK: - MainTab

private enum MainTab: CaseIterable, Sendable {
    case home
    case search
    case movie
    case series
    case memberSetting

    var kind: MainTabKind {
        switch self {
        case .home:
            return .home

        case .search:
            return .search

        case .movie:
            return .movie

        case .series:
            return .series

        case .memberSetting:
            return .memberSetting
        }
    }

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .home:
            return localization.string(
                "main_tab.home.title",
                defaultValue: "Home"
            )

        case .search:
            return localization.string(
                "main_tab.search.title",
                defaultValue: "Search"
            )

        case .movie:
            return localization.string(
                "main_tab.movie.title",
                defaultValue: "Movies"
            )

        case .series:
            return localization.string(
                "main_tab.series.title",
                defaultValue: "TV Shows"
            )

        case .memberSetting:
            return localization.string(
                "main_tab.settings.title",
                defaultValue: "Settings"
            )
        }
    }

    var imageName: String {
        switch self {
        case .home:
            return "flame"

        case .search:
            return "magnifyingglass"

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

        case .search:
            return "magnifyingglass"

        case .movie:
            return "film.stack.fill"

        case .series:
            return "tv.fill"

        case .memberSetting:
            return "person.crop.circle.fill"
        }
    }

    func accessibilityText(localization: AppInterfaceLocalization) -> AccessibilityText {
        let localizedTitle = title(localization: localization)

        return AccessibilityText(
            label: localization.formatted(
                "main_tab.accessibility.label_format",
                defaultValue: "%@ tab",
                localizedTitle
            ),
            hint: localization.formatted(
                "main_tab.accessibility.hint_format",
                defaultValue: "Double-tap to switch to %@",
                localizedTitle
            )
        )
    }
}
