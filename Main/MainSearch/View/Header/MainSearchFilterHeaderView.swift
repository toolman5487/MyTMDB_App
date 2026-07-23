//
//  MainSearchFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import UIKit

// MARK: - MainSearchFilterHeaderView

@MainActor
final class MainSearchFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: MainSearchFilterHeaderView.self)

    var onFilterSelected: ((MainSearchFilter) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
    }

    func configure(filters: [MainSearchFilterItem]) {
        onBaseFilterSelected = { [weak self] item in
            guard let filter = MainSearchFilter(rawValue: item.id) else { return }
            self?.onFilterSelected?(filter)
        }

        configure(filters: filters.map(BaseFilterHeaderItem.init(searchFilter:)))
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(searchFilter: MainSearchFilterItem) {
        self.init(
            id: searchFilter.id,
            title: searchFilter.title,
            isSelected: searchFilter.isSelected
        )
    }
}
