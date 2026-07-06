//
//  MovieSortMenuFactory.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MovieSortMenuFactory

@MainActor
enum MovieSortMenuFactory {

    static func makeMenu(
        selectedOption: MovieSortOption?,
        onSelect: @escaping (MovieSortOption) -> Void
    ) -> UIMenu {
        let actions = MovieSortOption.allCases.map { option in
            UIAction(
                title: option.title,
                state: selectedOption == option ? .on : .off
            ) { _ in
                Task { @MainActor in
                    onSelect(option)
                }
            }
        }

        return UIMenu(
            title: "篩選排序",
            options: .singleSelection,
            children: actions
        )
    }

    static func makeBarButtonItem(
        selectedOption: MovieSortOption?,
        onSelect: @escaping (MovieSortOption) -> Void
    ) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: makeMenu(selectedOption: selectedOption, onSelect: onSelect)
        )
        barButtonItem.tintColor = ThemeColor.textPrimary
        return barButtonItem
    }
}
