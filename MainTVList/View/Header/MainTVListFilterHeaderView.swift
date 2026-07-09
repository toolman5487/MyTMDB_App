//
//  MainTVListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListFilterHeaderView

@MainActor
final class MainTVListFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: MainTVListFilterHeaderView.self)

    func configure(
        filters: [MainTVGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        configure(
            filters: filters.map(BaseFilterHeaderItem.init(tvGenre:)),
            isExpanded: isExpanded,
            isShowingSkeleton: isShowingSkeleton
        )
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(tvGenre: MainTVGenreItem) {
        self.init(
            id: tvGenre.id,
            name: tvGenre.name,
            isSelected: tvGenre.isSelected
        )
    }
}
