//
//  SeasonDetailCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SDWebImage
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
final class SeasonDetailEpisodesCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailEpisodesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 260, height: 236)
    }

    private var episodes: [SeasonEpisodeItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.register(
            SeasonDetailEpisodeCollectionViewCell.self,
            forCellWithReuseIdentifier: SeasonDetailEpisodeCollectionViewCell.reuseIdentifier
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
        episodes = []
        collectionView.reloadData()
    }

    func configure(episodes: [SeasonEpisodeItem]) {
        self.episodes = episodes
        collectionView.reloadData()
    }
}

extension SeasonDetailEpisodesCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        episodes.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SeasonDetailEpisodeCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? SeasonDetailEpisodeCollectionViewCell)?.configure(with: episodes[indexPath.item])
        return cell
    }
}

@MainActor
private final class SeasonDetailEpisodeCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailEpisodeCollectionViewCell.self)

    private enum Layout {
        static let imageHeight: CGFloat = 124
        static let contentInset: CGFloat = 12
        static let itemSpacing: CGFloat = 6
    }

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel = SeasonDetailCellFactory.makeTitleLabel(numberOfLines: 2)
    private let subtitleLabel = SeasonDetailCellFactory.makeSubtitleLabel(numberOfLines: 1)
    private let overviewLabel = SeasonDetailCellFactory.makeSubtitleLabel(numberOfLines: 2)

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(imageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(overviewLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.imageHeight)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(Layout.contentInset)
            make.leading.trailing.equalToSuperview().inset(Layout.contentInset)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.equalTo(titleLabel)
        }

        overviewLabel.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(Layout.itemSpacing)
            make.leading.trailing.lessThanOrEqualTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(Layout.contentInset)
        }
    }

    override func resetForReuse() {
        imageView.sd_cancelCurrentImageLoad()
        imageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        overviewLabel.text = nil
    }

    func configure(with item: SeasonEpisodeItem) {
        imageView.sd_setImage(with: item.stillURL)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        overviewLabel.text = item.overview
    }
}

// MARK: - SeasonDetailImageStripCollectionViewCell

nonisolated struct SeasonDetailImageStripItem: Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String?
    let imageURL: URL?
}

@MainActor
final class SeasonDetailImageStripCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailImageStripCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [SeasonDetailImageStripItem] = []
    private var onItemSelected: ((SeasonDetailImageStripItem) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            SeasonDetailImageStripItemCell.self,
            forCellWithReuseIdentifier: SeasonDetailImageStripItemCell.reuseIdentifier
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
        onItemSelected = nil
        collectionView.reloadData()
    }

    func configure(
        items: [SeasonDetailImageStripItem],
        onItemSelected: ((SeasonDetailImageStripItem) -> Void)? = nil
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        collectionView.reloadData()
    }
}

extension SeasonDetailImageStripCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: SeasonDetailImageStripItemCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? SeasonDetailImageStripItemCell)?.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onItemSelected?(items[indexPath.item])
    }
}

@MainActor
private final class SeasonDetailImageStripItemCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: SeasonDetailImageStripItemCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(imageHeight: 168)
    }

    func configure(with item: SeasonDetailImageStripItem) {
        configure(
            imageURL: item.imageURL,
            title: item.title,
            subtitle: item.subtitle
        )
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
        items.forEach { stackView.addArrangedSubview(makeRow(for: $0)) }
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

    private func makeRow(for item: SeasonDetailTextListItem) -> UIView {
        let titleLabel = SeasonDetailCellFactory.makeTitleLabel(numberOfLines: 2)
        titleLabel.text = item.title

        let subtitleLabel = SeasonDetailCellFactory.makeSubtitleLabel(numberOfLines: 3)
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }

    private func removeRows() {
        stackView.arrangedSubviews.forEach { view in
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
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

// MARK: - Helpers

@MainActor
private enum SeasonDetailCellFactory {

    static func makeTitleLabel(numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = numberOfLines
        return label
    }

    static func makeSubtitleLabel(numberOfLines: Int) -> UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = numberOfLines
        return label
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
