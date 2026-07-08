//
//  EpisodeDetailCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SnapKit
import UIKit

// MARK: - EpisodeDetailFactsCollectionViewCell

@MainActor
final class EpisodeDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailFactsCollectionViewCell.self)

    func configure(facts: [EpisodeDetailFactItem]) {
        configure(
            facts: facts.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - EpisodeDetailVideosCollectionViewCell

@MainActor
final class EpisodeDetailVideosCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailVideosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
        static let imageHeight: CGFloat = 120
    }

    func configure(
        videos: [EpisodeVideoItem],
        onVideoSelected: @escaping (EpisodeVideoItem) -> Void
    ) {
        configure(
            items: videos.map {
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
            guard let video = videos.first(where: { $0.id == item.id }) else { return }
            onVideoSelected(video)
        }
    }
}

// MARK: - EpisodeDetailCastCollectionViewCell

@MainActor
final class EpisodeDetailCastCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailCastCollectionViewCell.self)

    func configure(
        cast: [EpisodePersonItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(cast, onPersonSelected: onPersonSelected)
    }
}

// MARK: - EpisodeDetailGuestStarsCollectionViewCell

@MainActor
final class EpisodeDetailGuestStarsCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailGuestStarsCollectionViewCell.self)

    func configure(
        guestStars: [EpisodePersonItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(guestStars, onPersonSelected: onPersonSelected)
    }
}

// MARK: - EpisodeDetailCrewCollectionViewCell

@MainActor
final class EpisodeDetailCrewCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailCrewCollectionViewCell.self)

    func configure(
        crew: [EpisodePersonItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(crew, onPersonSelected: onPersonSelected)
    }
}

private extension DetailImageTitleStripCollectionViewCell {

    enum EpisodePeopleLayout {
        static let itemSize = CGSize(width: 112, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configureEpisodePeople(
        _ people: [EpisodePersonItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: people.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.profileURL,
                    title: $0.title,
                    subtitle: $0.subtitle
                )
            },
            itemSize: EpisodePeopleLayout.itemSize,
            imageHeight: EpisodePeopleLayout.imageHeight
        ) { item in
            guard let personID = people.first(where: { $0.id == item.id })?.personID else { return }
            onPersonSelected(personID)
        }
    }
}

// MARK: - EpisodeDetailImagesCollectionViewCell

@MainActor
final class EpisodeDetailImagesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailImagesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
        static let imageHeight: CGFloat = 120
    }

    func configure(images: [EpisodeImageItem]) {
        configure(
            items: images.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.imageURL,
                    title: "劇照",
                    subtitle: nil
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        )
    }
}

// MARK: - EpisodeDetailExternalLinksCollectionViewCell

@MainActor
final class EpisodeDetailExternalLinksCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailExternalLinksCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 72, height: 88)
        static let sectionHeight: CGFloat = 88
        static let itemSpacing: CGFloat = 16
    }

    private var items: [EpisodeExternalLinkItem] = []
    var onLinkSelected: ((URL) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionViewFlowLayout.minimumLineSpacing = Layout.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = Layout.itemSpacing
        collectionViewFlowLayout.sectionInset = .zero
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            EpisodeDetailExternalLinkCollectionViewCell.self,
            forCellWithReuseIdentifier: EpisodeDetailExternalLinkCollectionViewCell.reuseIdentifier
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
        onLinkSelected = nil
        collectionView.reloadData()
    }

    func configure(
        items: [EpisodeExternalLinkItem],
        onLinkSelected: @escaping (URL) -> Void
    ) {
        self.items = items
        self.onLinkSelected = onLinkSelected
        collectionView.reloadData()
    }

    static func fittingHeight(for items: [EpisodeExternalLinkItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return Layout.sectionHeight
    }
}

extension EpisodeDetailExternalLinksCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: EpisodeDetailExternalLinkCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? EpisodeDetailExternalLinkCollectionViewCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onLinkSelected?(items[indexPath.item].url)
    }
}

@MainActor
private final class EpisodeDetailExternalLinkCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailExternalLinkCollectionViewCell.self)

    private enum Layout {
        static let iconContainerSize: CGFloat = 56
        static let iconSize: CGFloat = 26
        static let titleTopSpacing: CGFloat = 8
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18) {
                self.containerView.alpha = self.isHighlighted ? 0.72 : 1
                self.containerView.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                    : .identity
            }
        }
    }

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.clipsToBounds = true
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func configureView() {
        containerView.backgroundColor = .clear
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconContainerView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.width.height.equalTo(Layout.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainerView.snp.bottom).offset(Layout.titleTopSpacing)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func resetForReuse() {
        containerView.alpha = 1
        containerView.transform = .identity
        containerView.layer.borderColor = nil
        iconImageView.image = nil
        iconImageView.tintColor = nil
        iconContainerView.backgroundColor = nil
        titleLabel.text = nil
    }

    func configure(with item: EpisodeExternalLinkItem) {
        let style = EpisodeDetailExternalLinkStyle(id: item.id)

        if let imageName = style.imageName,
           let image = UIImage(named: imageName) {
            iconImageView.image = image.withRenderingMode(.alwaysOriginal)
            iconImageView.tintColor = nil
        } else {
            iconImageView.image = UIImage(systemName: style.symbolName)
            iconImageView.tintColor = style.tintColor
        }

        iconContainerView.backgroundColor = .clear
        titleLabel.text = item.title
    }
}

private struct EpisodeDetailExternalLinkStyle {
    let imageName: String?
    let symbolName: String
    let tintColor: UIColor

    init(id: String) {
        switch id.lowercased() {
        case "imdb":
            self.imageName = "imdb_icon"
            self.symbolName = "film.circle.fill"
            self.tintColor = ThemeColor.spotlightGold

        case "wikidata":
            self.imageName = "wiki_icon"
            self.symbolName = "w.circle.fill"
            self.tintColor = ThemeColor.systemGreen

        default:
            self.imageName = nil
            self.symbolName = "arrow.up.forward.circle.fill"
            self.tintColor = ThemeColor.highlight
        }
    }
}

// MARK: - EpisodeDetailAccountStateCollectionViewCell

nonisolated struct EpisodeDetailTextListItem: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
}

@MainActor
final class EpisodeDetailAccountStateCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailAccountStateCollectionViewCell.self)

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
    }

    private var items: [EpisodeDetailTextListItem] = []
    private var onItemSelected: ((EpisodeDetailTextListItem) -> Void)?

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.itemSpacing
        return stackView
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.contentInset)
        }
    }

    override func resetForReuse() {
        items = []
        onItemSelected = nil
        removeRows()
    }

    func configure(
        items: [EpisodeDetailTextListItem],
        onItemSelected: ((EpisodeDetailTextListItem) -> Void)? = nil
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        removeRows()
        items.forEach { item in
            let rowView = EpisodeDetailTextListRowView()
            rowView.configure(with: item)
            rowView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapRow(_:))))
            rowView.isUserInteractionEnabled = onItemSelected != nil
            stackView.addArrangedSubview(rowView)
        }
    }

    static func fittingHeight(
        for items: [EpisodeDetailTextListItem],
        width: CGFloat
    ) -> CGFloat {
        let contentWidth = width - (Layout.contentInset * 2)
        guard contentWidth > 0 else { return 80 }

        let textHeight = items.reduce(CGFloat.zero) { result, item in
            result
                + item.title.height(
                    constrainedTo: contentWidth,
                    font: .preferredFont(forTextStyle: .headline)
                )
                + (item.subtitle?.height(
                    constrainedTo: contentWidth,
                    font: .preferredFont(forTextStyle: .subheadline)
                ) ?? 0)
        }
        let spacing = CGFloat(max(items.count - 1, 0)) * Layout.itemSpacing
        return ceil(textHeight + spacing + (Layout.contentInset * 2))
    }

    @objc
    private func didTapRow(_ recognizer: UITapGestureRecognizer) {
        guard let rowView = recognizer.view as? EpisodeDetailTextListRowView,
              let index = stackView.arrangedSubviews.firstIndex(where: { $0 === rowView }),
              items.indices.contains(index) else {
            return
        }

        onItemSelected?(items[index])
    }

    private func removeRows() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

@MainActor
private final class EpisodeDetailTextListRowView: UIView {

    private enum Layout {
        static let itemSpacing: CGFloat = 4
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.itemSpacing
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 3
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    func configure(with item: EpisodeDetailTextListItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true
    }

    private func setupHierarchy() {
        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(subtitleLabel)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

// MARK: - EpisodeDetailOverviewCollectionViewCell

@MainActor
final class EpisodeDetailOverviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailOverviewCollectionViewCell.self)

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 148
        static let titleContentSpacing: CGFloat = 8
        static let bodyLineSpacing: CGFloat = 4
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
        overviewLabel.attributedText = Self.overviewAttributedText(overview: overview)
    }

    static func fittingHeight(for overview: String, width: CGFloat) -> CGFloat {
        let contentWidth = width - (Layout.contentInset * 2)
        guard contentWidth > 0 else {
            return Layout.minimumHeight
        }

        let attributedText = overviewAttributedText(overview: overview)
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

    private static func overviewAttributedText(overview: String) -> NSAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = Layout.titleContentSpacing

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = Layout.bodyLineSpacing

        let attributedText = NSMutableAttributedString(
            string: "集數簡介\n",
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

private extension String {

    func height(
        constrainedTo width: CGFloat,
        font: UIFont
    ) -> CGFloat {
        let rect = (self as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return ceil(rect.height)
    }
}
