//
//  MainTVGenrePageSheetViewController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/17.
//

import UIKit

// MARK: - MainTVGenreItem

extension MainTVGenreItem: GenrePageSheetItemRepresentable {}

// MARK: - MainTVGenrePageSheetViewController

@MainActor
final class MainTVGenrePageSheetViewController: BaseGenrePageSheetViewController<MainTVGenreItem> {

    // MARK: - Initialization

    init(
        filters: [MainTVGenreItem],
        onFilterSelected: @escaping (Int) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        super.init(
            title: "劇集種類",
            filters: filters,
            onFilterSelected: onFilterSelected,
            onDismiss: onDismiss
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
