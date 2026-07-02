//
//  TVDetailCells.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - TVDetailOverviewCollectionViewCell

@MainActor
final class TVDetailOverviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailOverviewCollectionViewCell.self)

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

// MARK: - TVDetailFactsCollectionViewCell

@MainActor
final class TVDetailFactsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailFactsCollectionViewCell.self)

    private enum Layout {
        static let itemHeight: CGFloat = 96
    }

    private var facts: [TVDetailFactItem] = []
    private var previousCollectionWidth: CGFloat = 0

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailFactCardCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailFactCardCollectionViewCell.reuseIdentifier
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

    func configure(facts: [TVDetailFactItem]) {
        self.facts = facts
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }
}

extension TVDetailFactsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        facts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailFactCardCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? TVDetailFactCardCollectionViewCell {
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

        return TVDetailFactCardCollectionViewCell.fittingSize(
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
private final class TVDetailFactCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailFactCardCollectionViewCell.self)

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

    func configure(with item: TVDetailFactItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
    }

    static func fittingSize(
        for item: TVDetailFactItem,
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

// MARK: - TVDetailAttributesCollectionViewCell

@MainActor
final class TVDetailAttributesCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailAttributesCollectionViewCell.self)

    private enum Layout {
        static let collectionHeight: CGFloat = 36
        static let titleCollectionSpacing: CGFloat = 12
        static let titleWidth: CGFloat = 64
        static let groupSpacing: CGFloat = 12
        static let itemSpacing: CGFloat = 8
    }

    private enum AttributeGroup {
        case genres
        case networks
        case productionCompanies
    }

    private var genres: [TVDetailAttributeItem] = []
    private var networks: [TVDetailAttributeItem] = []
    private var productionCompanies: [TVDetailAttributeItem] = []

    private let genresTitleLabel = TVDetailCellStyle.makeGroupTitleLabel(text: "種類")
    private let networksTitleLabel = TVDetailCellStyle.makeGroupTitleLabel(text: "平台")
    private let productionCompaniesTitleLabel = TVDetailCellStyle.makeGroupTitleLabel(text: "製作公司")

    private let genresCollectionViewFlowLayout = TVDetailCellStyle.makeFlowLayout()
    private let networksCollectionViewFlowLayout = TVDetailCellStyle.makeFlowLayout()
    private let productionCompaniesCollectionViewFlowLayout = TVDetailCellStyle.makeFlowLayout()

    private lazy var genresCollectionView = makeCollectionView(layout: genresCollectionViewFlowLayout)
    private lazy var networksCollectionView = makeCollectionView(layout: networksCollectionViewFlowLayout)
    private lazy var productionCompaniesCollectionView = makeCollectionView(layout: productionCompaniesCollectionViewFlowLayout)

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

    private lazy var networksRowStackView = makeRowStackView(
        titleLabel: networksTitleLabel,
        collectionView: networksCollectionView
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
        verticalStackView.addArrangedSubview(networksRowStackView)
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

        networksCollectionView.snp.makeConstraints { make in
            make.height.equalTo(Layout.collectionHeight)
        }

        productionCompaniesCollectionView.snp.makeConstraints { make in
            make.height.equalTo(Layout.collectionHeight)
        }
    }

    override func resetForReuse() {
        genres = []
        networks = []
        productionCompanies = []
        setGroup(.genres, hidden: false)
        setGroup(.networks, hidden: false)
        setGroup(.productionCompanies, hidden: false)
        genresCollectionView.reloadData()
        networksCollectionView.reloadData()
        productionCompaniesCollectionView.reloadData()
    }

    func configure(with item: TVDetailAttributeSectionItem) {
        genres = item.genres
        networks = item.networks
        productionCompanies = item.productionCompanies
        setGroup(.genres, hidden: genres.isEmpty)
        setGroup(.networks, hidden: networks.isEmpty)
        setGroup(.productionCompanies, hidden: productionCompanies.isEmpty)
        genresCollectionView.reloadData()
        networksCollectionView.reloadData()
        productionCompaniesCollectionView.reloadData()
    }

    private func setGroup(_ group: AttributeGroup, hidden: Bool) {
        switch group {
        case .genres:
            genresRowStackView.isHidden = hidden

        case .networks:
            networksRowStackView.isHidden = hidden

        case .productionCompanies:
            productionCompaniesRowStackView.isHidden = hidden
        }
    }

    private func makeCollectionView(layout: UICollectionViewFlowLayout) -> UICollectionView {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailAttributePillCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailAttributePillCollectionViewCell.reuseIdentifier
        )
        return collectionView
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

    static func fittingHeight(for item: TVDetailAttributeSectionItem) -> CGFloat {
        let groupCount = [
            item.genres.isEmpty,
            item.networks.isEmpty,
            item.productionCompanies.isEmpty
        ].filter { !$0 }.count

        guard groupCount > 0 else { return 0 }

        return (CGFloat(groupCount) * Layout.collectionHeight)
            + (CGFloat(groupCount - 1) * Layout.groupSpacing)
    }

    private func group(for collectionView: UICollectionView) -> AttributeGroup {
        switch collectionView {
        case genresCollectionView:
            return .genres

        case networksCollectionView:
            return .networks

        default:
            return .productionCompanies
        }
    }

    private func items(for group: AttributeGroup) -> [TVDetailAttributeItem] {
        switch group {
        case .genres:
            return genres

        case .networks:
            return networks

        case .productionCompanies:
            return productionCompanies
        }
    }
}

extension TVDetailAttributesCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items(for: group(for: collectionView)).count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailAttributePillCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        let items = items(for: group(for: collectionView))

        if let cell = cell as? TVDetailAttributePillCollectionViewCell {
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

        return TVDetailAttributePillCollectionViewCell.fittingSize(
            for: items[indexPath.item],
            maximumWidth: collectionView.bounds.width
        )
    }
}

@MainActor
private final class TVDetailAttributePillCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailAttributePillCollectionViewCell.self)

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

    func configure(with item: TVDetailAttributeItem) {
        titleLabel.text = item.title
    }

    static func fittingSize(for item: TVDetailAttributeItem, maximumWidth: CGFloat) -> CGSize {
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

// MARK: - Shared Horizontal Poster Cells

@MainActor
final class TVDetailCastCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 220)
    }

    private var items: [TVDetailCastItem] = []
    private var onPersonSelected: ((Int) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailCastPersonCell.self,
            forCellWithReuseIdentifier: TVDetailCastPersonCell.reuseIdentifier
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
        items: [TVDetailCastItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        self.items = items
        self.onPersonSelected = onPersonSelected
        collectionView.reloadData()
    }
}

extension TVDetailCastCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailCastPersonCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? TVDetailCastPersonCell {
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
private final class TVDetailCastPersonCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailCastPersonCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 168
        )
    }

    func configure(with item: TVDetailCastItem) {
        configure(
            imageURL: item.profileURL,
            title: item.name,
            subtitle: Self.makeSubtitle(for: item)
        )
    }

    private static func makeSubtitle(for item: TVDetailCastItem) -> String? {
        let values = [
            item.characterText,
            item.episodeCountText
        ].filter { !$0.isEmpty }

        return values.isEmpty ? nil : values.joined(separator: " · ")
    }
}

@MainActor
final class TVDetailVideosCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailVideosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
    }

    private var items: [TVDetailVideoItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailVideoThumbnailCell.self,
            forCellWithReuseIdentifier: TVDetailVideoThumbnailCell.reuseIdentifier
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

    func configure(items: [TVDetailVideoItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension TVDetailVideosCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailVideoThumbnailCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? TVDetailVideoThumbnailCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

@MainActor
private final class TVDetailVideoThumbnailCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailVideoThumbnailCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 112
        )
    }

    func configure(with item: TVDetailVideoItem) {
        configure(
            imageURL: item.thumbnailURL,
            title: item.title,
            subtitle: item.subtitle
        )
    }
}

@MainActor
final class TVDetailSeasonsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailSeasonsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [TVDetailSeasonItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailSeasonPosterCell.self,
            forCellWithReuseIdentifier: TVDetailSeasonPosterCell.reuseIdentifier
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

    func configure(items: [TVDetailSeasonItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension TVDetailSeasonsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailSeasonPosterCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? TVDetailSeasonPosterCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

@MainActor
private final class TVDetailSeasonPosterCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailSeasonPosterCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 168
        )
    }

    func configure(with item: TVDetailSeasonItem) {
        configure(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: item.subtitle
        )
    }
}

@MainActor
final class TVDetailRecommendationsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailRecommendationsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [TVDetailRecommendationItem] = []
    private var onRecommendationSelected: ((Int) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailRecommendationPosterCell.self,
            forCellWithReuseIdentifier: TVDetailRecommendationPosterCell.reuseIdentifier
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
        items: [TVDetailRecommendationItem],
        onRecommendationSelected: @escaping (Int) -> Void
    ) {
        self.items = items
        self.onRecommendationSelected = onRecommendationSelected
        collectionView.reloadData()
    }
}

extension TVDetailRecommendationsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailRecommendationPosterCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? TVDetailRecommendationPosterCell {
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
private final class TVDetailRecommendationPosterCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailRecommendationPosterCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(
            imageHeight: 168
        )
    }

    func configure(with item: TVDetailRecommendationItem) {
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

private enum TVDetailCellStyle {

    private enum Layout {
        static let itemSpacing: CGFloat = 8
    }

    static func makeImageView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }

    static func makeTextLabel(font: UIFont, color: UIColor) -> UILabel {
        let label = UILabel()
        label.font = font
        label.adjustsFontForContentSizeCategory = true
        label.textColor = color
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    static func makeGroupTitleLabel(text: String) -> UILabel {
        let label = makeTextLabel(
            font: .preferredFont(forTextStyle: .caption1),
            color: ThemeColor.textSecondary
        )
        label.text = text
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }

    static func makeFlowLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        return layout
    }
}
