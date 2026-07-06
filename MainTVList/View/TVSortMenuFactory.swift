//
//  TVSortMenuFactory.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - TVSortMenuFactory

@MainActor
enum TVSortMenuFactory {

    static func makeMenu(
        selectedOption: TVSortOption?,
        onSelect: @escaping (TVSortOption) -> Void
    ) -> UIMenu {
        let actions = TVSortOption.allCases.map { option in
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
        selectedOption: TVSortOption?,
        onSelect: @escaping (TVSortOption) -> Void
    ) -> UIBarButtonItem {
        let barButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: makeMenu(selectedOption: selectedOption, onSelect: onSelect)
        )
        barButtonItem.tintColor = ThemeColor.textPrimary
        return barButtonItem
    }
}
