//
//  TVDetailReviewFilterCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import UIKit

// MARK: - TVDetailReviewFilterCollectionViewCell

@MainActor
final class TVDetailReviewFilterCollectionViewCell: BaseFilterHeaderCollectionViewCell {

    // MARK: - Configuration

    func configure(with item: TVDetailReviewFilterItem) {
        configure(
            title: item.title,
            isSelected: item.isSelected
        )
    }
}
