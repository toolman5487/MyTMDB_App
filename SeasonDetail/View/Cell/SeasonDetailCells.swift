//
//  SeasonDetailCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - SeasonDetailFactsCollectionViewCell

@MainActor
final class SeasonDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailFactsCollectionViewCell.self)

    func configure(facts: [SeasonDetailFactItem]) {
        configure(
            facts: facts.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - SeasonDetailEpisodesCollectionViewCell

@MainActor
final class SeasonDetailEpisodesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailEpisodesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
        static let imageHeight: CGFloat = 120
    }

    func configure(
        episodes: [SeasonEpisodeItem],
        onEpisodeSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: episodes.map {
                DetailImageTitleItem(
                    id: String($0.episodeNumber),
                    imageURL: $0.stillURL,
                    title: $0.title,
                    subtitle: $0.subtitle
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let episodeNumber = Int(item.id) else { return }
            onEpisodeSelected(episodeNumber)
        }
    }
}

// MARK: - SeasonDetailVideosCollectionViewCell

@MainActor
final class SeasonDetailVideosCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailVideosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 220, height: 148)
        static let imageHeight: CGFloat = 120
    }

    func configure(
        videos: [SeasonVideoItem],
        onVideoSelected: @escaping (SeasonVideoItem) -> Void
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

// MARK: - SeasonDetailCastCollectionViewCell

@MainActor
final class SeasonDetailCastCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailCastCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        cast: [SeasonCastItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: cast.map {
                DetailImageTitleItem(
                    id: String($0.id),
                    imageURL: $0.profileURL,
                    title: $0.title,
                    subtitle: $0.subtitle
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

// MARK: - SeasonDetailCrewCollectionViewCell

@MainActor
final class SeasonDetailCrewCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailCrewCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 112, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        crew: [SeasonCrewItem],
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configure(
            items: crew.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.profileURL,
                    title: $0.title,
                    subtitle: $0.subtitle
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let personID = crew.first(where: { $0.id == item.id })?.personID else { return }
            onPersonSelected(personID)
        }
    }
}

// MARK: - SeasonDetailImagesCollectionViewCell

@MainActor
final class SeasonDetailImagesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailImagesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(gallery: SeasonImageGalleryItem) {
        configure(
            items: detailItems(from: gallery),
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        )
    }

    private func detailItems(from gallery: SeasonImageGalleryItem) -> [DetailImageTitleItem] {
        let items = gallery.posters.map {
            DetailImageTitleItem(
                id: "poster-\($0.id)",
                imageURL: $0.imageURL,
                title: "海報",
                subtitle: nil
            )
        } + gallery.backdrops.map {
            DetailImageTitleItem(
                id: "backdrop-\($0.id)",
                imageURL: $0.imageURL,
                title: "劇照",
                subtitle: nil
            )
        } + gallery.logos.map {
            DetailImageTitleItem(
                id: "logo-\($0.id)",
                imageURL: $0.imageURL,
                title: "Logo",
                subtitle: nil
            )
        }

        return Array(items.prefix(DetailSectionPreviewLimit.itemCount))
    }
}

// MARK: - SeasonDetailWatchProvidersCollectionViewCell

@MainActor
final class SeasonDetailWatchProvidersCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailWatchProvidersCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        providers: [SeasonWatchProviderItem],
        onProviderSelected: @escaping (SeasonWatchProviderItem) -> Void
    ) {
        configure(
            items: providers.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.logoURL,
                    title: $0.title,
                    subtitle: "\($0.countryCode) · \($0.category)"
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

// MARK: - SeasonDetailTextListCollectionViewCell

nonisolated struct SeasonDetailTextListItem: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
}

@MainActor
final class SeasonDetailTextListCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailTextListCollectionViewCell.self)

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
    }

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
        removeRows()
    }

    func configure(items: [SeasonDetailTextListItem]) {
        removeRows()
        items.forEach {
            let rowView = SeasonDetailTextListRowView()
            rowView.configure(with: $0)
            stackView.addArrangedSubview(rowView)
        }
    }

    static func fittingHeight(
        for items: [SeasonDetailTextListItem],
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

    private func removeRows() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}

@MainActor
private final class SeasonDetailTextListRowView: UIView {

    private enum Layout {
        static let itemSpacing: CGFloat = 4
    }

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Layout.itemSpacing
        return stackView
    }()

    private let titleLabel = AppFactory.Label.headline(lines: 2)

    private let subtitleLabel = AppFactory.Label.subheadline(lines: 3)

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

    func configure(with item: SeasonDetailTextListItem) {
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

// MARK: - SeasonDetailOverviewCollectionViewCell

@MainActor
final class SeasonDetailOverviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailOverviewCollectionViewCell.self)

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 148
        static let titleContentSpacing: CGFloat = 8
        static let bodyLineSpacing: CGFloat = 4
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
            string: "季數簡介\n",
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
