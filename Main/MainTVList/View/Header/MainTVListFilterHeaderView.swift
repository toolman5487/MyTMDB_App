//
//  MainTVListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListFilterHeaderView

@MainActor
final class MainTVListFilterHeaderView: BaseShowAllFilterHeaderView {

    static let reuseIdentifier = String(describing: MainTVListFilterHeaderView.self)

    var onFilterSelected: ((Int) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
    }

    func configure(
        filters: [MainTVGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        onBaseFilterSelected = { [weak self] item in
            guard let id = Int(item.id) else { return }
            self?.onFilterSelected?(id)
        }

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
            id: String(tvGenre.id),
            title: tvGenre.name,
            isSelected: tvGenre.isSelected
        )
    }
}
