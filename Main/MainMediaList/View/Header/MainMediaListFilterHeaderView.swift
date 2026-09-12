//
//  MainMediaListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMediaListFilterHeaderView

@MainActor
final class MainMediaListFilterHeaderView: BaseShowAllFilterHeaderView {

    static let reuseIdentifier = String(describing: MainMediaListFilterHeaderView.self)

    var onFilterSelected: ((Int) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
    }

    func configure(
        filters: [MainMediaGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        onBaseFilterSelected = { [weak self] item in
            guard let id = Int(item.id) else { return }
            self?.onFilterSelected?(id)
        }

        configure(
            filters: filters.map(BaseFilterHeaderItem.init(movieGenre:)),
            isExpanded: isExpanded,
            isShowingSkeleton: isShowingSkeleton
        )
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(movieGenre: MainMediaGenreItem) {
        self.init(
            id: String(movieGenre.id),
            title: movieGenre.name,
            isSelected: movieGenre.isSelected
        )
    }
}
