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

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 148
        static let titleContentSpacing: CGFloat = 8
    }

    private let overviewLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 0)

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
            make.edges.equalToSuperview().inset(Layout.contentInset)
        }
    }

    override func resetForReuse() {
        overviewLabel.text = nil
        overviewLabel.attributedText = nil
    }

    func configure(overview: String) {
        overviewLabel.attributedText = Self.makeOverviewAttributedText(overview: overview)
    }

    static func fittingHeight(for overview: String, width: CGFloat) -> CGFloat {
        let contentWidth = width - (Layout.contentInset * 2)
        guard contentWidth > 0 else {
            return Layout.minimumHeight
        }

        let attributedText = makeOverviewAttributedText(overview: overview)
        let textHeight = attributedText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height

        return max(
            Layout.minimumHeight,
            ceil(textHeight) + (Layout.contentInset * 2)
        )
    }

    private static func makeOverviewAttributedText(overview: String) -> NSAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = Layout.titleContentSpacing

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 4

        let attributedText = NSMutableAttributedString(
            string: "劇情簡介\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: ThemeColor.textPrimary,
                .paragraphStyle: titleParagraphStyle
            ]
        )
        attributedText.append(
            NSAttributedString(
                string: overview,
                attributes: [
                    .font: UIFont.preferredFont(forTextStyle: .body),
                    .foregroundColor: ThemeColor.textPrimary,
                    .paragraphStyle: bodyParagraphStyle
                ]
            )
        )

        return attributedText
    }
}

// MARK: - MovieDetailFactsCollectionViewCell

@MainActor
final class MovieDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailFactsCollectionViewCell.self)

    func configure(facts: [MovieDetailFactItem]) {
        configure(
            facts: facts.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - MovieDetailAttributesCollectionViewCell

@MainActor
final class MovieDetailAttributesCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailAttributesCollectionViewCell.self)

    private enum Layout {
        static let collectionHeight: CGFloat = 36
        static let titleCollectionSpacing: CGFloat = 12
        static let titleWidth: CGFloat = 64
        static let groupSpacing: CGFloat = 12
        static let itemSpacing: CGFloat = 8
    }

    private enum AttributeGroup {
        case genres
        case productionCompanies
    }

    private var genres: [MovieDetailAttributeItem] = []
    private var productionCompanies: [MovieDetailAttributeItem] = []

    private let genresTitleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(color: ThemeColor.textSecondary, lines: 1)
        label.text = "種類"
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let productionCompaniesTitleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(color: ThemeColor.textSecondary, lines: 1)
        label.text = "製作公司"
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let genresCollectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        return layout
    }()

    private let productionCompaniesCollectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        return layout
    }()

    private lazy var genresCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: genresCollectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailAttributePillCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailAttributePillCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var productionCompaniesCollectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: productionCompaniesCollectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            MovieDetailAttributePillCollectionViewCell.self,
            forCellWithReuseIdentifier: MovieDetailAttributePillCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private let verticalStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.groupSpacing
        return stackView
    }()

    private lazy var genresRowStackView = makeRowStackView(
        titleLabel: genresTitleLabel,
        collectionView: genresCollectionView
    )

    private lazy var productionCompaniesRowStackView = makeRowStackView(
        titleLabel: productionCompaniesTitleLabel,
        collectionView: productionCompaniesCollectionView
    )

    override func configureView() {
        containerView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(verticalStackView)
        verticalStackView.addArrangedSubview(genresRowStackView)
        verticalStackView.addArrangedSubview(productionCompaniesRowStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        verticalStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        genresCollectionView.snp.makeConstraints { make in
            make.height.equalTo(Layout.collectionHeight)
        }

        productionCompaniesCollectionView.snp.makeConstraints { make in
            make.height.equalTo(Layout.collectionHeight)
        }
    }

    override func resetForReuse() {
        genres = []
        productionCompanies = []
        setGroup(.genres, hidden: false)
        setGroup(.productionCompanies, hidden: false)
        genresCollectionView.reloadData()
        productionCompaniesCollectionView.reloadData()
    }

    func configure(with item: MovieDetailAttributeSectionItem) {
        genres = item.genres
        productionCompanies = item.productionCompanies
        setGroup(.genres, hidden: genres.isEmpty)
        setGroup(.productionCompanies, hidden: productionCompanies.isEmpty)
        genresCollectionView.reloadData()
        productionCompaniesCollectionView.reloadData()
    }

    private func setGroup(_ group: AttributeGroup, hidden: Bool) {
        switch group {
        case .genres:
            genresRowStackView.isHidden = hidden

        case .productionCompanies:
            productionCompaniesRowStackView.isHidden = hidden
        }
    }

    private func makeRowStackView(
        titleLabel: UILabel,
        collectionView: UICollectionView
    ) -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: [titleLabel, collectionView])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.titleCollectionSpacing
        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(Layout.titleWidth)
        }
        return stackView
    }

    static func fittingHeight(for item: MovieDetailAttributeSectionItem) -> CGFloat {
        let groupCount = [
            item.genres.isEmpty,
            item.productionCompanies.isEmpty
        ].filter { !$0 }.count

        guard groupCount > 0 else { return 0 }

        return (CGFloat(groupCount) * Layout.collectionHeight)
            + (CGFloat(groupCount - 1) * Layout.groupSpacing)
    }

    private func group(for collectionView: UICollectionView) -> AttributeGroup {
        collectionView === genresCollectionView ? .genres : .productionCompanies
    }

    private func items(for group: AttributeGroup) -> [MovieDetailAttributeItem] {
        switch group {
        case .genres:
            return genres

        case .productionCompanies:
            return productionCompanies
        }
    }
}

extension MovieDetailAttributesCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items(for: group(for: collectionView)).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MovieDetailAttributePillCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        let items = items(for: group(for: collectionView))

        if let cell = cell as? MovieDetailAttributePillCollectionViewCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let items = items(for: group(for: collectionView))
        guard items.indices.contains(indexPath.item) else {
            return .zero
        }

        return MovieDetailAttributePillCollectionViewCell.fittingSize(
            for: items[indexPath.item],
            maximumWidth: collectionView.bounds.width
        )
    }
}

@MainActor
private final class MovieDetailAttributePillCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailAttributePillCollectionViewCell.self)

    private enum Layout {
        static let height: CGFloat = 36
        static let minimumWidth: CGFloat = 64
        static let horizontalInset: CGFloat = 16
    }

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(lines: 1)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.borderColor = ThemeColor.highlight.cgColor
        containerView.layer.borderWidth = 2
        containerView.layer.cornerRadius = Layout.height / 2
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
        }
    }

    override func resetForReuse() {
        titleLabel.text = nil
    }

    func configure(with item: MovieDetailAttributeItem) {
        titleLabel.text = item.title
    }

    static func fittingSize(for item: MovieDetailAttributeItem, maximumWidth: CGFloat) -> CGSize {
        let measuredWidth = (item.title as NSString).size(
            withAttributes: [.font: UIFont.preferredFont(forTextStyle: .caption1)]
        ).width
        let fittingWidth = ceil(measuredWidth) + (Layout.horizontalInset * 2)
        let width = min(
            max(Layout.minimumWidth, fittingWidth),
            max(Layout.minimumWidth, maximumWidth)
        )

        return CGSize(width: width, height: Layout.height)
    }
}

// MARK: - MovieDetailCastCollectionViewCell

@MainActor
final class MovieDetailCastCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [MovieDetailCastItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: String($0.id),
                    imageURL: $0.profileURL,
                    title: $0.name,
                    subtitle: $0.characterText
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let personID = Int(item.id) else { return }
            onPersonSelected(personID)
        }
    }
}

// MARK: - MovieDetailVideosCollectionViewCell

@MainActor
final class MovieDetailVideosCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailVideosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
        static let imageHeight: CGFloat = 120
    }

    func configure(
        items: [MovieDetailVideoItem],
        onVideoSelected: @escaping (MovieDetailVideoItem) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.thumbnailURL,
                    title: $0.title,
                    subtitle: $0.subtitle
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let video = items.first(where: { $0.id == item.id }) else { return }
            onVideoSelected(video)
        }
    }
}

// MARK: - MovieDetailImagesCollectionViewCell

@MainActor
final class MovieDetailImagesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailImagesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 168)
        static let imageHeight: CGFloat = 124
    }

    func configure(
        items: [MovieDetailImageItem],
        onImageSelected: @escaping (MovieDetailImageItem) -> Void
    ) {
        let imageItemsByID = items.reduce(into: [String: MovieDetailImageItem]()) { result, item in
            result[item.id] = item
        }
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.imageURL,
                    title: $0.title,
                    subtitle: $0.resolutionText
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let imageItem = imageItemsByID[item.id] else { return }
            onImageSelected(imageItem)
        }
    }
}

// MARK: - MovieDetailCollectionPartsCollectionViewCell

@MainActor
final class MovieDetailCollectionPartsCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCollectionPartsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        item: MovieDetailCollectionSectionItem,
        onMovieSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: item.parts.map {
                DetailImageTitleItem(
                    id: String($0.id),
                    imageURL: $0.posterURL,
                    title: $0.title,
                    subtitle: $0.subtitle
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let movieID = Int(item.id) else { return }
            onMovieSelected(movieID)
        }
    }
}

// MARK: - MovieDetailWatchProvidersCollectionViewCell

@MainActor
final class MovieDetailWatchProvidersCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailWatchProvidersCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 96, height: 144)
        static let imageHeight: CGFloat = 96
    }

    func configure(
        providers: [MovieWatchProviderItem],
        onProviderSelected: @escaping (MovieWatchProviderItem) -> Void
    ) {
        configure(
            items: providers.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.logoURL,
                    title: $0.title,
                    subtitle: BaseDisplayTextFormatter.metadata([$0.countryCode, $0.category])
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let provider = providers.first(where: { $0.id == item.id }) else { return }
            onProviderSelected(provider)
        }
    }
}

// MARK: - MovieDetailRecommendationsCollectionViewCell

@MainActor
final class MovieDetailRecommendationsCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailRecommendationsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [MovieDetailRecommendationItem],
        onRecommendationSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: String($0.id),
                    imageURL: $0.posterURL,
                    title: $0.title,
                    subtitle: BaseDisplayTextFormatter.ratingText($0.scoreText)
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let recommendationID = Int(item.id) else { return }
            onRecommendationSelected(recommendationID)
        }
    }
}
