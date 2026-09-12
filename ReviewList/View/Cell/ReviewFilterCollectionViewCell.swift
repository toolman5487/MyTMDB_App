//
//  ReviewFilterCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import UIKit

// MARK: - ReviewFilterCollectionViewCell

@MainActor
final class ReviewFilterCollectionViewCell: BaseFilterHeaderCollectionViewCell {

    // MARK: - Configuration

    func configure(with item: ReviewFilterItem) {
        configure(
            title: item.title,
            isSelected: item.isSelected
        )
    }
}
