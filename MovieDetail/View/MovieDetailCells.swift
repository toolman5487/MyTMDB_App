//
//  MovieDetailCells.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MovieDetailHeroCollectionViewCell

@MainActor
final class MovieDetailHeroCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailHeroCollectionViewCell.self)

    private enum Layout {
        static let backdropHeight: CGFloat = 220
        static let posterWidth: CGFloat = 112
        static let posterHeight: CGFloat = 168
    }

    private let backdropImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let posterImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title2).scaledFont(
            for: .systemFont(ofSize: 24, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let originalTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let taglineLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.highlight
        label.numberOfLines = 2
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let scoreLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .headline).scaledFont(
            for: .systemFont(ofSize: 17, weight: .semibold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    override func configureView() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(backdropImageView)
        containerView.addSubview(posterImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(originalTitleLabel)
        containerView.addSubview(taglineLabel)
        containerView.addSubview(metadataLabel)
        containerView.addSubview(scoreLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        backdropImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.backdropHeight)
        }

        posterImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(backdropImageView.snp.bottom).offset(-72)
            make.width.equalTo(Layout.posterWidth)
            make.height.equalTo(Layout.posterHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backdropImageView.snp.bottom).offset(16)
            make.leading.equalTo(posterImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
        }

        originalTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.trailing.equalTo(titleLabel)
        }

        metadataLabel.snp.makeConstraints { make in
            make.top.equalTo(originalTitleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        scoreLabel.snp.makeConstraints { make in
            make.top.equalTo(metadataLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }

        taglineLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    override func resetForReuse() {
        backdropImageView.sd_cancelCurrentImageLoad()
        posterImageView.sd_cancelCurrentImageLoad()
        backdropImageView.image = nil
        posterImageView.image = nil
        titleLabel.text = nil
        originalTitleLabel.text = nil
        taglineLabel.text = nil
        metadataLabel.text = nil
        scoreLabel.text = nil
    }

    func configure(with item: MovieDetailHeroItem) {
        backdropImageView.sd_setImage(with: item.backdropURL)
        posterImageView.sd_setImage(with: item.posterURL)
        titleLabel.text = item.title
        originalTitleLabel.text = item.originalTitle == item.title ? nil : item.originalTitle
        taglineLabel.text = item.tagline
        metadataLabel.text = item.metadataText
        scoreLabel.text = "評分 \(item.scoreText)  \(item.voteCountText)"
    }
}

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
        contentView.backgroundColor = ThemeColor.backgroundSecondary
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
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
final class MovieDetailFactsCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailFactsCollectionViewCell.self)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        return stackView
    }()

    override func configureView() {
        contentView.backgroundColor = ThemeColor.backgroundSecondary
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }

    override func resetForReuse() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func configure(facts: [MovieDetailFactItem]) {
        resetForReuse()

        for fact in facts {
            stackView.addArrangedSubview(makeFactRow(fact))
        }
    }

    private func makeFactRow(_ fact: MovieDetailFactItem) -> UIView {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .caption1)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = ThemeColor.textSecondary
        titleLabel.text = fact.title
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.font = .preferredFont(forTextStyle: .subheadline)
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.textColor = ThemeColor.textPrimary
        valueLabel.numberOfLines = 2
        valueLabel.textAlignment = .right
        valueLabel.text = fact.value

        let rowStackView = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        rowStackView.axis = .horizontal
        rowStackView.alignment = .top
        rowStackView.spacing = 12
        return rowStackView
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
        contentView.backgroundColor = .clear
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
        contentView.backgroundColor = .clear
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
        contentView.backgroundColor = .clear
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
