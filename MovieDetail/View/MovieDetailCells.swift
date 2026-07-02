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

    private let accentView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.highlight
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
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
            measuredWidth(for: item.title, font: .preferredFont(forTextStyle: .callout)),
            measuredWidth(for: item.value, font: .preferredFont(forTextStyle: .title3))
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
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.text = "種類"
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let productionCompaniesTitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
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
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.textAlignment = .center
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
final class MovieDetailCastCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 220)
    }

    private var items: [MovieDetailCastItem] = []
    private var onPersonSelected: ((Int) -> Void)?

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
        onPersonSelected = nil
        collectionView.reloadData()
    }

    func configure(
        items: [MovieDetailCastItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        self.items = items
        self.onPersonSelected = onPersonSelected
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onPersonSelected?(items[indexPath.item].id)
    }
}

@MainActor
private final class MovieDetailCastPersonCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailCastPersonCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 168
        )
    }

    func configure(with item: MovieDetailCastItem) {
        configure(
            imageURL: item.profileURL,
            title: item.name,
            subtitle: item.characterText
        )
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

@MainActor
private final class MovieDetailVideoThumbnailCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailVideoThumbnailCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 120
        )
    }

    func configure(with item: MovieDetailVideoItem) {
        configure(
            imageURL: item.thumbnailURL,
            title: item.title,
            subtitle: item.subtitle
        )
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
    private var onRecommendationSelected: ((Int) -> Void)?

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
        onRecommendationSelected = nil
        collectionView.reloadData()
    }

    func configure(
        items: [MovieDetailRecommendationItem],
        onRecommendationSelected: @escaping (Int) -> Void
    ) {
        self.items = items
        self.onRecommendationSelected = onRecommendationSelected
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onRecommendationSelected?(items[indexPath.item].id)
    }
}

@MainActor
private final class MovieDetailRecommendationPosterCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MovieDetailRecommendationPosterCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 168
        )
    }

    func configure(with item: MovieDetailRecommendationItem) {
        let subtitle: String?
        if let scoreText = item.scoreText {
            subtitle = "評分 \(scoreText)"
        } else {
            subtitle = nil
        }

        configure(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: subtitle
        )
    }
}
