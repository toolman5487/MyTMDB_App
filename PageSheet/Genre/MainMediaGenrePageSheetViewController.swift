//
//  MainMediaGenrePageSheetViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMediaGenreItem

extension MainMediaGenreItem: GenrePageSheetItemRepresentable {}

// MARK: - MainMediaGenrePageSheetViewController

@MainActor
final class MainMediaGenrePageSheetViewController: BaseGenrePageSheetViewController<MainMediaGenreItem> {

    // MARK: - Initialization

    init(
        kind: MediaKind,
        filters: [MainMediaGenreItem],
        interfaceLocalization: AppInterfaceLocalization,
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        super.init(
            title: interfaceLocalization.formatted(
                "genre_sheet.title_format",
                defaultValue: "%@ Genres",
                kind.displayName(localization: interfaceLocalization)
            ),
            filters: filters,
            interfaceLocalization: interfaceLocalization,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
