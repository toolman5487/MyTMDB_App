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
        static let itemHeight: CGFloat = 96
    }

    private var facts: [MovieDetailFactItem] = []
    private var previousCollectionWidth: CGFloat = 0

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
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

    override func layoutSubviews() {
        super.layoutSubviews()

        guard collectionView.bounds.width != previousCollectionWidth else { return }

        previousCollectionWidth = collectionView.bounds.width
        collectionViewFlowLayout.invalidateLayout()
    }

    override func resetForReuse() {
        facts = []
        collectionView.reloadData()
    }

    func configure(facts: [MovieDetailFactItem]) {
        self.facts = facts
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }
}

extension MovieDetailFactsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard facts.indices.contains(indexPath.item) else {
            return .zero
        }

        return MovieDetailFactCardCollectionViewCell.fittingSize(
            for: facts[indexPath.item],
            height: Layout.itemHeight,
            maximumWidth: maximumCardWidth(in: collectionView)
        )
    }

    private func maximumCardWidth(in collectionView: UICollectionView) -> CGFloat {
        let availableWidth = collectionView.bounds.width > 0
            ? collectionView.bounds.width
            : bounds.width
        let sectionInset = collectionViewFlowLayout.sectionInset

        return max(
            availableWidth - sectionInset.left - sectionInset.right,
            0
        )
    }
}

@MainActor
private final class MovieDetailFactCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailFactCardCollectionViewCell.self)

    private enum Layout {
        static let accentWidth: CGFloat = 4
        static let titleTopInset: CGFloat = 12
        static let contentLeadingInset: CGFloat = 16
        static let contentTrailingInset: CGFloat = 12
        static let valueBottomInset: CGFloat = 12
    }

    private static var titleFont: UIFont {
        .preferredFont(forTextStyle: .callout)
    }

    private static var valueFont: UIFont {
        .preferredFont(forTextStyle: .title3)
    }

    private let accentView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.highlight
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = titleFont
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = valueFont
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.minimumScaleFactor = 0.82
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
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
            make.width.equalTo(Layout.accentWidth)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.titleTopInset)
            make.leading.equalToSuperview().inset(Layout.contentLeadingInset)
            make.trailing.equalToSuperview().inset(Layout.contentTrailingInset)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(Layout.contentTrailingInset)
            make.bottom.equalToSuperview().inset(Layout.valueBottomInset)
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

    static func fittingSize(
        for item: MovieDetailFactItem,
        height: CGFloat,
        maximumWidth: CGFloat
    ) -> CGSize {
        let textWidth = max(
            measuredWidth(for: item.title, font: titleFont),
            measuredWidth(for: item.value, font: valueFont)
        )
        let fittingWidth = ceil(
            textWidth + Layout.contentLeadingInset + Layout.contentTrailingInset
        )
        let width = maximumWidth > 0
            ? min(fittingWidth, maximumWidth)
            : fittingWidth

        return CGSize(width: width, height: height)
    }

    private static func measuredWidth(for text: String, font: UIFont) -> CGFloat {
        (text as NSString).size(withAttributes: [.font: font]).width
    }
}

// MARK: - MovieDetailCastCollectionViewCell

@MainActor
final class MovieDetailCastCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 232)
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

    private enum Layout {
        static let profileImageHeight: CGFloat = 168
        static let textTopSpacing: CGFloat = 4
        static let subtitleTopBottomSpacing: CGFloat = 2
    }

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let characterLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

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
            make.height.equalTo(Layout.profileImageHeight)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(profileImageView.snp.bottom).offset(Layout.textTopSpacing)
            make.leading.trailing.equalToSuperview()
        }

        characterLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(Layout.subtitleTopBottomSpacing)
            make.leading.trailing.equalToSuperview()
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

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

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
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
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
