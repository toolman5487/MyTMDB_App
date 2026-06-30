//
//  MovieDetailCells.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MovieDetailOverviewCollectionViewCell

@MainActor
final class MovieDetailOverviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailOverviewCollectionViewCell.self)

    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 0
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(overviewLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        overviewLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    override func resetForReuse() {
        overviewLabel.text = nil
    }

    func configure(overview: String) {
        overviewLabel.text = overview
    }
}

// MARK: - MovieDetailFactsCollectionViewCell

@MainActor
final class MovieDetailFactsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailFactsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 156, height: 104)
    }

    private var facts: [MovieDetailFactItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.register(
            MovieDetailFactCardCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailFactCardCollectionViewCell.reuseIdentifier
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
        facts = []
        collectionView.reloadData()
    }

    func configure(facts: [MovieDetailFactItem]) {
        self.facts = facts
        collectionView.reloadData()
    }
}

extension MovieDetailFactsCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        facts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailFactCardCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MovieDetailFactCardCollectionViewCell {
            cell.configure(with: facts[indexPath.item])
        }

        return cell
    }
}

@MainActor
private final class MovieDetailFactCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailFactCardCollectionViewCell.self)

    private let accentView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.highlight
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.82
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 16
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(accentView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        accentView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.width.equalTo(8)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(12)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview().inset(12)
        }
    }

    override func resetForReuse() {
        titleLabel.text = nil
        valueLabel.text = nil
    }

    func configure(with item: MovieDetailFactItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
    }
}

// MARK: - MovieDetailCastCollectionViewCell

@MainActor
final class MovieDetailCastCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 168)
    }

    private var items: [MovieDetailCastItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailCastPersonCell.self,
            forCellWithReuseIdentifier: MovieDetailCastPersonCell.reuseIdentifier
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
        collectionView.reloadData()
    }

    func configure(items: [MovieDetailCastItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension MovieDetailCastCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailCastPersonCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MovieDetailCastPersonCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - MovieDetailVideosCollectionViewCell

@MainActor
final class MovieDetailVideosCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailVideosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
    }

    private var items: [MovieDetailVideoItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailVideoThumbnailCell.self,
            forCellWithReuseIdentifier: MovieDetailVideoThumbnailCell.reuseIdentifier
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
        collectionView.reloadData()
    }

    func configure(items: [MovieDetailVideoItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension MovieDetailVideosCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailVideoThumbnailCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MovieDetailVideoThumbnailCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - MovieDetailRecommendationsCollectionViewCell

@MainActor
final class MovieDetailRecommendationsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailRecommendationsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [MovieDetailRecommendationItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailRecommendationPosterCell.self,
            forCellWithReuseIdentifier: MovieDetailRecommendationPosterCell.reuseIdentifier
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
        collectionView.reloadData()
    }

    func configure(items: [MovieDetailRecommendationItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension MovieDetailRecommendationsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailRecommendationPosterCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MovieDetailRecommendationPosterCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

// MARK: - Private Nested Cells

@MainActor
private final class MovieDetailCastPersonCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastPersonCell.self)

    private let profileImageView = MovieDetailCellFactory.makePosterImageView(cornerRadius: 8)
    private let nameLabel = MovieDetailCellFactory.makeCardTitleLabel()
    private let characterLabel = MovieDetailCellFactory.makeCardSubtitleLabel()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(profileImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(characterLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        profileImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(112)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }

        characterLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func resetForReuse() {
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = nil
        nameLabel.text = nil
        characterLabel.text = nil
    }

    func configure(with item: MovieDetailCastItem) {
        profileImageView.sd_setImage(with: item.profileURL)
        nameLabel.text = item.name
        characterLabel.text = item.characterText
    }
}

@MainActor
private final class MovieDetailVideoThumbnailCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailVideoThumbnailCell.self)

    private let thumbnailImageView = MovieDetailCellFactory.makePosterImageView(cornerRadius: 8)
    private let titleLabel = MovieDetailCellFactory.makeCardTitleLabel()
    private let subtitleLabel = MovieDetailCellFactory.makeCardSubtitleLabel()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        thumbnailImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(112)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnailImageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func resetForReuse() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        thumbnailImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
    }

    func configure(with item: MovieDetailVideoItem) {
        thumbnailImageView.sd_setImage(with: item.thumbnailURL)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
    }
}

@MainActor
private final class MovieDetailRecommendationPosterCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailRecommendationPosterCell.self)

    private let posterImageView = MovieDetailCellFactory.makePosterImageView(cornerRadius: 8)
    private let titleLabel = MovieDetailCellFactory.makeCardTitleLabel()
    private let scoreLabel = MovieDetailCellFactory.makeCardSubtitleLabel()

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(posterImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(scoreLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        posterImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(168)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(6)
            make.leading.trailing.equalToSuperview()
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.bottom.lessThanOrEqualToSuperview()
        }
    }

    override func resetForReuse() {
        posterImageView.sd_cancelCurrentImageLoad()
        posterImageView.image = nil
        titleLabel.text = nil
        scoreLabel.text = nil
    }

    func configure(with item: MovieDetailRecommendationItem) {
        posterImageView.sd_setImage(with: item.posterURL)
        titleLabel.text = item.title
        scoreLabel.text = "評分 \(item.scoreText)"
    }
}

// MARK: - Shared Helpers

@MainActor
private enum MovieDetailCellFactory {

    static func makePosterImageView(cornerRadius: CGFloat) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = cornerRadius
        return imageView
    }

    static func makeCardTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        return label
    }

    static func makeCardSubtitleLabel() -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }
}
