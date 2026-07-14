//
//  HomeSectionListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/9.
//

import UIKit

// MARK: - HomeSectionListFilterHeaderView

@MainActor
final class HomeSectionListFilterHeaderView: BaseShowAllFilterHeaderView {

    static let reuseIdentifier = String(describing: HomeSectionListFilterHeaderView.self)

    var onFilterSelected: ((Int) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
    }

    func configure(
        filters: [HomeSectionListGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        onBaseFilterSelected = { [weak self] item in
            guard let id = Int(item.id) else { return }
            self?.onFilterSelected?(id)
        }

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
            id: String(genreItem.id),
            title: genreItem.name,
            isSelected: genreItem.isSelected
        )
    }
}
