//
//  TVDetailReviewFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

// MARK: - TVDetailReviewFilterHeaderView

@MainActor
final class TVDetailReviewFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: TVDetailReviewFilterHeaderView.self)

    private var filtersByBaseID: [String: TVDetailReviewFilter] = [:]
    var onFilterSelected: ((TVDetailReviewFilter) -> Void)?

    override func prepareForReuse() {
        super.prepareForReuse()
        filtersByBaseID = [:]
        onFilterSelected = nil
    }

    func configure(filters: [TVDetailReviewFilterItem]) {
        filtersByBaseID = Dictionary(
            uniqueKeysWithValues: filters.map { ($0.id.baseFilterID, $0.id) }
        )
        onBaseFilterSelected = { [weak self] item in
            guard let filter = self?.filtersByBaseID[item.id] else { return }
            self?.onFilterSelected?(filter)
        }

        configure(filters: filters.map(BaseFilterHeaderItem.init(tvReviewFilter:)))
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(tvReviewFilter item: TVDetailReviewFilterItem) {
        self.init(
            id: item.id.baseFilterID,
            title: item.title,
            isSelected: item.isSelected
        )
    }
}

private extension TVDetailReviewFilter {

    var baseFilterID: String {
        String(describing: self)
    }
}
