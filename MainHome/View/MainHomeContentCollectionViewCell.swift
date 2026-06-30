//
//  MainHomeContentCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SDWebImage
import SkeletonView
import SnapKit
import UIKit

// MARK: - MainHomeContentCollectionViewCell

@MainActor
final class MainHomeContentCollectionViewCell: BaseCollectionViewCell {

    // MARK: - Constants

    private enum CellIdentifier {
        static let poster = String(describing: MainHomePosterCollectionViewCell.self)
    }

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
    }

    // MARK: - Properties

    private var contents: [MainHomeContentItem] = []

    // MARK: - UI Components

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Layout.horizontalInset,
            bottom: 0,
            right: Layout.horizontalInset
        )
        layout.itemSize = CGSize(
            width: Layout.posterWidth,
            height: Layout.itemHeight
        )
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MainHomePosterCollectionViewCell.self,
            forCellWithReuseIdentifier: CellIdentifier.poster
        )
        return collectionView
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
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
        contents = []
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    // MARK: - Configuration

    func configure(contents: [MainHomeContentItem]) {
        self.contents = contents
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeContentCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contents.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CellIdentifier.poster,
            for: indexPath
        )

        if let cell = cell as? MainHomePosterCollectionViewCell {
            cell.configure(with: contents[indexPath.item])
        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeContentCollectionViewCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

// MARK: - MainHomePosterCollectionViewCell

@MainActor
private final class MainHomePosterCollectionViewCell: BaseCollectionViewCell {

    // MARK: - Constants

    private enum Layout {
        static let posterHeight: CGFloat = 186
    }

    // MARK: - UI Components

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.tintColor = ThemeColor.textTertiary
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.isSkeletonable = true
        return imageView
    }()

    private let mediaTypeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.highlight
        label.numberOfLines = 1
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        contentView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(posterImageView)
        containerView.addSubview(mediaTypeLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scoreLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        posterImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.posterHeight)
        }

        mediaTypeLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(mediaTypeLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        posterImageView.sd_cancelCurrentImageLoad()
        posterImageView.image = nil
        showPosterSkeletonIfNeeded()
        mediaTypeLabel.text = nil
        titleLabel.text = nil
        scoreLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: MainHomeContentItem) {
        posterImageView.image = nil
        showPosterSkeletonIfNeeded()

        if let posterURL = item.posterURL {
            posterImageView.sd_setImage(with: posterURL) { [weak self] image, _, _, _ in
                guard let self else { return }

                if image == nil {
                    showPosterSkeletonIfNeeded()
                } else {
                    hidePosterSkeletonIfNeeded()
                }
            }
        }

        mediaTypeLabel.text = item.mediaTypeText
        titleLabel.text = item.title
        scoreLabel.text = "評分 \(item.scoreText)"
    }

    // MARK: - Skeleton

    private func showPosterSkeletonIfNeeded() {
        guard !posterImageView.sk.isSkeletonActive else { return }
        posterImageView.showAnimatedGradientSkeleton()
    }

    private func hidePosterSkeletonIfNeeded() {
        guard posterImageView.sk.isSkeletonActive else { return }
        posterImageView.hideSkeleton()
    }
}
