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
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        super.init(
            title: "\(kind.displayName)種類",
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
