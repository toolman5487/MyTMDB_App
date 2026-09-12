//
//  ReviewFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

// MARK: - ReviewFilterHeaderView

@MainActor
final class ReviewFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: ReviewFilterHeaderView.self)

    private var filtersByBaseID: [String: ReviewFilter] = [:]
    var onFilterSelected: ((ReviewFilter) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        filtersByBaseID = [:]
        onFilterSelected = nil
    }

    func configure(filters: [ReviewFilterItem]) {
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

    init(movieReviewFilter item: ReviewFilterItem) {
        self.init(
            id: item.id.baseFilterID,
            title: item.title,
            isSelected: item.isSelected
        )
    }
}

private extension ReviewFilter {

    var baseFilterID: String {
        String(describing: self)
    }
}
