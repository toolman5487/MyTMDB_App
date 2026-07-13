//
//  DetailImageTitleStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/7.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - DetailImageTitleStripCollectionViewCell

@MainActor
class DetailImageTitleStripCollectionViewCell: BaseHorizontalStripCollectionViewCell<
    DetailImageTitleItem,
    DetailImageTitleCollectionViewCell
> {

    private enum Layout {
        static let defaultItemSize = CGSize(width: 124, height: 220)
        static let defaultImageHeight: CGFloat = 168
    }

    override func configureView() {
        super.configureView()
        configureHorizontalStrip(
            cellType: DetailImageTitleCollectionViewCell.self,
            reuseIdentifier: DetailImageTitleCollectionViewCell.reuseIdentifier,
            itemSize: Layout.defaultItemSize
        )
    }

    override func resetForReuse() {
        super.resetForReuse()
        updateItemSize(Layout.defaultItemSize)
    }

    func configure(
        items: [DetailImageTitleItem],
        itemSize: CGSize = Layout.defaultItemSize,
        imageHeight: CGFloat = Layout.defaultImageHeight,
        onItemSelected: ((DetailImageTitleItem) -> Void)? = nil
    ) {
        updateItemSize(itemSize)
        configureItems(
            items,
            onItemSelected: onItemSelected
        ) { cell, item in
            cell.configure(with: item, imageHeight: imageHeight)
        }
    }
}

// MARK: - DetailImageTitleCollectionViewCell

@MainActor
final class DetailImageTitleCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailImageTitleCollectionViewCell.self)

    private enum Layout {
        static let imageHeight: CGFloat = 168
        static let imageCornerRadius: CGFloat = 8
        static let contentSpacing: CGFloat = 4
    }

    private var imageHeightConstraint: Constraint?

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = Layout.contentSpacing
        return stackView
    }()

    private let itemImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.imageCornerRadius
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = AppFactory.Label.captionSecondary(color: ThemeColor.textSecondary, lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(itemImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        itemImageView.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
            imageHeightConstraint = make.height.equalTo(Layout.imageHeight).constraint
        }

        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }
    }

    override func resetForReuse() {
        itemImageView.sd_cancelCurrentImageLoad()
        itemImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
        imageHeightConstraint?.update(offset: Layout.imageHeight)
    }

    func configure(with item: DetailImageTitleItem, imageHeight: CGFloat) {
        imageHeightConstraint?.update(offset: imageHeight)
        itemImageView.sd_setImage(with: item.imageURL)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true
    }
}
