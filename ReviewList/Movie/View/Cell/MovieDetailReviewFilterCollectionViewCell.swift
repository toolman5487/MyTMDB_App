//
//  MovieDetailReviewFilterCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import UIKit

// MARK: - MovieDetailReviewFilterCollectionViewCell

@MainActor
final class MovieDetailReviewFilterCollectionViewCell: BaseFilterHeaderCollectionViewCell {

    // MARK: - Configuration

    func configure(with item: MovieDetailReviewFilterItem) {
        configure(
            title: item.title,
            isSelected: item.isSelected
        )
    }
}
