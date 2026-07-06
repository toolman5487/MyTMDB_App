//
//  MovieDetailReviewFilterCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - MovieDetailReviewFilterCollectionViewCell

@MainActor
final class MovieDetailReviewFilterCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailReviewFilterCollectionViewCell.self)

    // MARK: - Properties

    private var item: MovieDetailReviewFilterItem?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 2
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: 16,
                    bottom: 0,
                    right: 16
                )
            )
        }
    }

    override func resetForReuse() {
        item = nil
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Configuration

    func configure(with item: MovieDetailReviewFilterItem) {
        self.item = item
        titleLabel.text = item.title
        titleLabel.textColor = item.isSelected ? .white : ThemeColor.textPrimary
        containerView.backgroundColor = item.isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        containerView.layer.borderColor = borderColor(isSelected: item.isSelected).cgColor
    }

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
    }
}
