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
        static let itemSize = DetailImageTitleStripMetrics.landscapePreviewItemSize
        static let imageHeight = DetailImageTitleStripMetrics.landscapePreviewImageHeight
    }

    func configure(
        videos: [EpisodeVideoItem],
        localization: AppInterfaceLocalization,
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
            imageHeight: Layout.imageHeight,
            localization: localization
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
        localization: AppInterfaceLocalization,
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(
            cast,
            localization: localization,
            onPersonSelected: onPersonSelected
        )
    }
}

// MARK: - EpisodeDetailGuestStarsCollectionViewCell

@MainActor
final class EpisodeDetailGuestStarsCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailGuestStarsCollectionViewCell.self)

    func configure(
        guestStars: [EpisodePersonItem],
        localization: AppInterfaceLocalization,
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(
            guestStars,
            localization: localization,
            onPersonSelected: onPersonSelected
        )
    }
}

// MARK: - EpisodeDetailCrewCollectionViewCell

@MainActor
final class EpisodeDetailCrewCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailCrewCollectionViewCell.self)

    func configure(
        crew: [EpisodePersonItem],
        localization: AppInterfaceLocalization,
        onPersonSelected: @escaping (Int) -> Void
    ) {
        configureEpisodePeople(
            crew,
            localization: localization,
            onPersonSelected: onPersonSelected
        )
    }
}

private extension DetailImageTitleStripCollectionViewCell {

    enum EpisodePeopleLayout {
        static let itemSize = CGSize(width: 112, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configureEpisodePeople(
        _ people: [EpisodePersonItem],
        localization: AppInterfaceLocalization,
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
            imageHeight: EpisodePeopleLayout.imageHeight,
            localization: localization
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
        static let itemSize = DetailImageTitleStripMetrics.landscapePreviewItemSize
        static let imageHeight = DetailImageTitleStripMetrics.landscapePreviewImageHeight
    }

    func configure(
        images: [EpisodeImageItem],
        localization: AppInterfaceLocalization,
        onImageSelected: @escaping (EpisodeImageItem) -> Void
    ) {
        let imageTitle = localization.string("detail.image.still", defaultValue: "Still")
        configure(
            items: images.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.imageURL,
                    title: imageTitle,
                    subtitle: nil
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight,
            localization: localization
        ) { item in
            guard let image = images.first(where: { $0.id == item.id }) else { return }
            onImageSelected(image)
        }
    }
}

// MARK: - EpisodeDetailExternalLinksCollectionViewCell

@MainActor
final class EpisodeDetailExternalLinksCollectionViewCell: DetailExternalLinkStripCollectionViewCell {

    static let reuseIdentifier = String(describing: EpisodeDetailExternalLinksCollectionViewCell.self)

    func configure(
        items: [EpisodeExternalLinkItem],
        localization: AppInterfaceLocalization,
        onLinkSelected: @escaping (URL) -> Void
    ) {
        configure(
            items: items.map {
                DetailExternalLinkItem(id: $0.id, title: $0.title, url: $0.url)
            },
            localization: localization,
            onLinkSelected: onLinkSelected
        )
    }

    static func fittingHeight(for items: [EpisodeExternalLinkItem]) -> CGFloat {
        DetailExternalLinkStripCollectionViewCell.fittingHeight(
            for: items.map {
                DetailExternalLinkItem(id: $0.id, title: $0.title, url: $0.url)
            }
        )
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

    override var containerViewInsets: UIEdgeInsets {
        DetailLayoutMetrics.horizontalContentInsets
    }

    private enum Layout {
        static let verticalContentInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
        static let rowTitleSubtitleSpacing: CGFloat = 4
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
        isAccessibilityElement = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalContentInset)
            make.leading.trailing.equalToSuperview().inset(DetailLayoutMetrics.horizontalContentInset)
        }
    }

    override func resetForReuse() {
        items = []
        onItemSelected = nil
        removeRows()
    }

    func configure(
        items: [EpisodeDetailTextListItem],
        localization: AppInterfaceLocalization,
        onItemSelected: ((EpisodeDetailTextListItem) -> Void)? = nil
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        removeRows()
        items.forEach { item in
            let rowView = EpisodeDetailTextListRowView()
            rowView.configure(
                with: item,
                selectionHint: onItemSelected == nil
                    ? nil
                    : localization.string(
                        "common.accessibility.action.hint",
                        defaultValue: "Double-tap to perform this action"
                    )
            )
            rowView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapRow(_:))))
            rowView.isUserInteractionEnabled = onItemSelected != nil
            stackView.addArrangedSubview(rowView)
        }
    }

    static func fittingHeight(
        for items: [EpisodeDetailTextListItem],
        width: CGFloat
    ) -> CGFloat {
        let contentWidth = DetailLayoutMetrics.contentWidth(
            for: width,
            horizontalInsetLevelCount: 2
        )
        guard contentWidth > 0 else { return 80 }

        let textHeight = items.reduce(CGFloat.zero) { result, item in
            let subtitleHeight = item.subtitle?.height(
                constrainedTo: contentWidth,
                font: .preferredFont(forTextStyle: .subheadline)
            ) ?? 0
            let titleSubtitleSpacing = subtitleHeight > 0 ? Layout.rowTitleSubtitleSpacing : 0

            return result
                + item.title.height(
                    constrainedTo: contentWidth,
                    font: .preferredFont(forTextStyle: .headline)
                )
                + titleSubtitleSpacing
                + subtitleHeight
        }
        let spacing = CGFloat(max(items.count - 1, 0)) * Layout.itemSpacing
        return ceil(textHeight + spacing + (Layout.verticalContentInset * 2))
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

    func configure(with item: EpisodeDetailTextListItem, selectionHint: String?) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
        applyAccessibilityText(
            AccessibilityText(
                label: item.title,
                value: BaseDisplayTextFormatter.nonEmptyText(item.subtitle),
                hint: selectionHint
            )
        )
        accessibilityTraits = selectionHint == nil ? .staticText : .button
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

    override var containerViewInsets: UIEdgeInsets {
        DetailLayoutMetrics.horizontalContentInsets
    }

    private enum Layout {
        static let verticalContentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 148
        static let titleContentSpacing: CGFloat = 8
        static let bodyLineSpacing: CGFloat = 4
    }

    private let overviewLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 0)

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        overviewLabel.isAccessibilityElement = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(overviewLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        overviewLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalContentInset)
            make.leading.trailing.equalToSuperview().inset(DetailLayoutMetrics.horizontalContentInset)
        }
    }

    override func resetForReuse() {
        overviewLabel.text = nil
        overviewLabel.attributedText = nil
        resetAccessibility()
    }

    func configure(
        overview: String,
        localization: AppInterfaceLocalization
    ) {
        let sectionTitle = Self.sectionTitle(localization: localization)
        overviewLabel.attributedText = Self.overviewAttributedText(
            overview: overview,
            sectionTitle: sectionTitle
        )
        applyAccessibility(
            AccessibilityText(
                label: sectionTitle,
                value: overview
            )
        )
    }

    static func fittingHeight(
        for overview: String,
        width: CGFloat,
        localization: AppInterfaceLocalization
    ) -> CGFloat {
        let contentWidth = DetailLayoutMetrics.contentWidth(
            for: width,
            horizontalInsetLevelCount: 2
        )
        guard contentWidth > 0 else {
            return Layout.minimumHeight
        }

        let attributedText = overviewAttributedText(
            overview: overview,
            sectionTitle: sectionTitle(localization: localization)
        )
        let textHeight = attributedText.boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height

        return max(
            Layout.minimumHeight,
            ceil(textHeight) + (Layout.verticalContentInset * 2)
        )
    }

    private static func sectionTitle(localization: AppInterfaceLocalization) -> String {
        localization.string(
            "episode_detail.overview.title",
            defaultValue: "Episode Overview"
        )
    }

    private static func overviewAttributedText(
        overview: String,
        sectionTitle: String
    ) -> NSAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = Layout.titleContentSpacing

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = Layout.bodyLineSpacing

        let attributedText = NSMutableAttributedString(
            string: "\(sectionTitle)\n",
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
