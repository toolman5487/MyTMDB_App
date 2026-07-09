//
//  HomeSectionListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import UIKit

// MARK: - HomeSectionListFilterHeaderView

@MainActor
final class HomeSectionListFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: HomeSectionListFilterHeaderView.self)

    func configure(
        filters: [HomeSectionListGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        configure(
            filters: filters.map(BaseFilterHeaderItem.init(genreItem:)),
            isExpanded: isExpanded,
            isShowingSkeleton: isShowingSkeleton
        )
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(genreItem: HomeSectionListGenreItem) {
        self.init(
            id: genreItem.id,
            name: genreItem.name,
            isSelected: genreItem.isSelected
        )
    }
}
