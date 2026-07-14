//
//  MainMovieListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import UIKit

// MARK: - MainMovieListFilterHeaderView

@MainActor
final class MainMovieListFilterHeaderView: BaseShowAllFilterHeaderView {

    static let reuseIdentifier = String(describing: MainMovieListFilterHeaderView.self)

    var onFilterSelected: ((Int) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
    }

    func configure(
        filters: [MainMovieGenreItem],
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

    init(movieGenre: MainMovieGenreItem) {
        self.init(
            id: String(movieGenre.id),
            title: movieGenre.name,
            isSelected: movieGenre.isSelected
        )
    }
}
