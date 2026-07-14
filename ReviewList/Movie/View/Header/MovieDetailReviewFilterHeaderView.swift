//
//  MovieDetailReviewFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

// MARK: - MovieDetailReviewFilterHeaderView

@MainActor
final class MovieDetailReviewFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: MovieDetailReviewFilterHeaderView.self)

    private var filtersByBaseID: [String: MovieDetailReviewFilter] = [:]
    var onFilterSelected: ((MovieDetailReviewFilter) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        filtersByBaseID = [:]
        onFilterSelected = nil
    }

    func configure(filters: [MovieDetailReviewFilterItem]) {
        filtersByBaseID = Dictionary(
            uniqueKeysWithValues: filters.map { ($0.id.baseFilterID, $0.id) }
        )
        onBaseFilterSelected = { [weak self] item in
            guard let filter = self?.filtersByBaseID[item.id] else { return }
            self?.onFilterSelected?(filter)
        }

        configure(filters: filters.map(BaseFilterHeaderItem.init(movieReviewFilter:)))
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(movieReviewFilter item: MovieDetailReviewFilterItem) {
        self.init(
            id: item.id.baseFilterID,
            title: item.title,
            isSelected: item.isSelected
        )
    }
}

private extension MovieDetailReviewFilter {

    var baseFilterID: String {
        String(describing: self)
    }
}
