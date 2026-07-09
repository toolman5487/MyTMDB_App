//
//  MainMovieListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieListFilterHeaderView

@MainActor
final class MainMovieListFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: MainMovieListFilterHeaderView.self)

    func configure(
        filters: [MainMovieGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        configure(
            filters: filters.map(BaseFilterHeaderItem.init(movieGenre:)),
            isExpanded: isExpanded,
            isShowingSkeleton: isShowingSkeleton
        )
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(movieGenre: MainMovieGenreItem) {
        self.init(
            id: movieGenre.id,
            name: movieGenre.name,
            isSelected: movieGenre.isSelected
        )
    }
}
