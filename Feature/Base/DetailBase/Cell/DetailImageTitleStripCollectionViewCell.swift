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
class DetailImageTitleStripCollectionViewCell: BaseNestedCollectionViewCell {

    private enum Layout {
        static let defaultItemSize = CGSize(width: 124, height: 220)
        static let defaultImageHeight: CGFloat = 168
    }

    private var items: [DetailImageTitleItem] = []
    private var imageHeight = Layout.defaultImageHeight
    private var onItemSelected: ((DetailImageTitleItem) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.defaultItemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            DetailImageTitleCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailImageTitleCollectionViewCell.reuseIdentifier
        )
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(collectionView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func resetForReuse() {
        items = []
        imageHeight = Layout.defaultImageHeight
        onItemSelected = nil
        collectionView.reloadData()
    }

    func configure(
        items: [DetailImageTitleItem],
        itemSize: CGSize = Layout.defaultItemSize,
        imageHeight: CGFloat = Layout.defaultImageHeight,
        onItemSelected: ((DetailImageTitleItem) -> Void)? = nil
    ) {
        self.items = items
        self.imageHeight = imageHeight
        self.onItemSelected = onItemSelected
        collectionViewFlowLayout.itemSize = itemSize
        collectionView.reloadData()
    }
}

extension DetailImageTitleStripCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetailImageTitleCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? DetailImageTitleCollectionViewCell {
            cell.configure(with: items[indexPath.item], imageHeight: imageHeight)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onItemSelected?(items[indexPath.item])
    }
}

// MARK: - DetailImageTitleCollectionViewCell

@MainActor
private final class DetailImageTitleCollectionViewCell: BaseCollectionViewCell {

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
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .natural
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .natural
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
