//
//  CompanyDetailCells.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - CompanyDetailHeroHeaderView

@MainActor
final class CompanyDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: CompanyDetailHeroHeaderView.self)

    private enum Layout {
        static let contentInset = DetailLayoutMetrics.horizontalContentInset
        static let logoSize: CGFloat = 96
        static let logoContentInset: CGFloat = 12
        static let logoCornerRadius: CGFloat = 8
        static let placeholderIconSize: CGFloat = 36

        static var height: CGFloat {
            logoSize + contentInset * 2
        }
    }

    private let logoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Layout.logoCornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let placeholderIconView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "building.2.fill"))
        imageView.tintColor = ThemeColor.gray3
        imageView.contentMode = .scaleAspectFit
        imageView.isAccessibilityElement = false
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = AppFactory.Label.title1(alignment: .natural, lines: 2)
        return label
    }()

    private let metadataLabel = AppFactory.Label.callout(lines: 2)

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        resetContent()
    }

    func configure(
        with item: CompanyDetailHeroItem,
        localization: AppInterfaceLocalization
    ) {
        placeholderIconView.isHidden = item.logoURL != nil
        logoImageView.sd_setImage(with: item.logoURL) { [weak self] image, _, _, _ in
            self?.placeholderIconView.isHidden = image != nil
        }
        nameLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            item.name,
            font: nameLabel.font ?? UIFont.preferredFont(forTextStyle: .title1)
        )
        metadataLabel.text = item.metadataText
        metadataLabel.isHidden = item.metadataText?.isEmpty != false
        logoImageView.applyAccessibilityText(
            AccessibilityText(
                label: localization.formatted(
                    "company_detail.logo.accessibility_label_format",
                    defaultValue: "Logo of %@",
                    item.name
                )
            )
        )
    }

    static func headerHeight() -> CGFloat {
        Layout.height
    }

    private func configureView() {
        backgroundColor = ThemeColor.background
        logoImageView.accessibilityTraits.insert(.image)
    }

    private func setupHierarchy() {
        addSubview(logoContainerView)
        logoContainerView.addSubview(logoImageView)
        logoContainerView.addSubview(placeholderIconView)
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(metadataLabel)
    }

    private func setupConstraints() {
        logoContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.contentInset)
            make.top.equalToSuperview().inset(Layout.contentInset)
            make.width.height.equalTo(Layout.logoSize)
        }

        logoImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.logoContentInset)
        }

        placeholderIconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.placeholderIconSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.leading.equalTo(logoContainerView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(Layout.contentInset)
            make.centerY.equalTo(logoContainerView)
        }
    }

    private func resetContent() {
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        placeholderIconView.isHidden = false
        nameLabel.attributedText = nil
        metadataLabel.text = nil
        metadataLabel.isHidden = false
        logoImageView.applyAccessibilityText(nil)
        logoImageView.accessibilityTraits.insert(.image)
    }
}

// MARK: - CompanyDetailDescriptionCollectionViewCell

@MainActor
final class CompanyDetailDescriptionCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailDescriptionCollectionViewCell.self)

    override var containerViewInsets: UIEdgeInsets {
        DetailLayoutMetrics.horizontalContentInsets
    }

    private enum Layout {
        static let verticalContentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 120
        static let titleContentSpacing: CGFloat = 8
    }

    private let descriptionLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 0)

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        descriptionLabel.isAccessibilityElement = false
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(descriptionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        descriptionLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(Layout.verticalContentInset)
            make.leading.trailing.equalToSuperview().inset(DetailLayoutMetrics.horizontalContentInset)
        }
    }

    override func resetForReuse() {
        descriptionLabel.attributedText = nil
        resetAccessibility()
    }

    func configure(
        description: String,
        localization: AppInterfaceLocalization
    ) {
        let sectionTitle = Self.sectionTitle(localization: localization)
        descriptionLabel.attributedText = Self.makeAttributedText(
            description: description,
            sectionTitle: sectionTitle
        )
        applyAccessibility(
            AccessibilityText(
                label: sectionTitle,
                value: description
            )
        )
    }

    static func fittingHeight(
        for description: String,
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

        let attributedText = makeAttributedText(
            description: description,
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
            "company_detail.description.title",
            defaultValue: "About"
        )
    }

    private static func makeAttributedText(
        description: String,
        sectionTitle: String
    ) -> NSAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = Layout.titleContentSpacing

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 4

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
                string: description,
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

// MARK: - CompanyDetailFactsCollectionViewCell

@MainActor
final class CompanyDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailFactsCollectionViewCell.self)

    func configure(facts: [CompanyDetailFactItem]) {
        configure(
            facts: facts.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - CompanyDetailMoviesCollectionViewCell

@MainActor
final class CompanyDetailMoviesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailMoviesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [CompanyDetailMediaItem],
        localization: AppInterfaceLocalization,
        onItemSelected: @escaping (CompanyDetailMediaItem) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.posterURL,
                    title: $0.title,
                    subtitle: Self.makeSubtitle(for: $0)
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight,
            localization: localization
        ) { item in
            guard let mediaItem = items.first(where: { $0.id == item.id }) else { return }
            onItemSelected(mediaItem)
        }
    }

    private static func makeSubtitle(for item: CompanyDetailMediaItem) -> String? {
        BaseDisplayTextFormatter.metadata([
            item.dateText,
            item.scoreText
        ])
    }
}

// MARK: - CompanyDetailTVShowsCollectionViewCell

@MainActor
final class CompanyDetailTVShowsCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailTVShowsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [CompanyDetailMediaItem],
        localization: AppInterfaceLocalization,
        onItemSelected: @escaping (CompanyDetailMediaItem) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.posterURL,
                    title: $0.title,
                    subtitle: Self.makeSubtitle(for: $0)
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight,
            localization: localization
        ) { item in
            guard let mediaItem = items.first(where: { $0.id == item.id }) else { return }
            onItemSelected(mediaItem)
        }
    }

    private static func makeSubtitle(for item: CompanyDetailMediaItem) -> String? {
        BaseDisplayTextFormatter.metadata([
            item.dateText,
            item.scoreText
        ])
    }
}

// MARK: - CompanyDetailLogosCollectionViewCell

@MainActor
final class CompanyDetailLogosCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailLogosCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [CompanyDetailLogoItem],
        localization: AppInterfaceLocalization,
        onImageSelected: @escaping (URL) -> Void
    ) {
        let fallbackTitle = localization.string(
            "company_detail.image.logo",
            defaultValue: "Logo"
        )
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.imageURL,
                    title: $0.sizeText.isEmpty ? fallbackTitle : $0.sizeText,
                    subtitle: nil
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight,
            imageBackgroundColor: .label,
            localization: localization
        ) { item in
            guard let logoItem = items.first(where: { $0.id == item.id }),
                  let imageURL = logoItem.imageURL else { return }
            onImageSelected(imageURL)
        }
    }
}

// MARK: - CompanyDetailAlternativeNamesCollectionViewCell

@MainActor
final class CompanyDetailAlternativeNamesCollectionViewCell: DetailPillListCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailAlternativeNamesCollectionViewCell.self)

    func configure(
        items: [CompanyDetailAlternativeNameItem],
        localization: AppInterfaceLocalization
    ) {
        configure(
            items: items.map { DetailPillItem(id: $0.id, title: $0.name) },
            itemAccessibilityLabel: localization.string(
                "company_detail.alternative_name.accessibility_label",
                defaultValue: "Alternative Name"
            ),
            localization: localization
        )
    }

    static func fittingHeight(for items: [CompanyDetailAlternativeNameItem]) -> CGFloat {
        fittingHeight(for: items.map { DetailPillItem(id: $0.id, title: $0.name) })
    }
}

// MARK: - CompanyDetailExternalLinksCollectionViewCell

@MainActor
final class CompanyDetailExternalLinksCollectionViewCell: DetailExternalLinkStripCollectionViewCell {

    static let reuseIdentifier = String(describing: CompanyDetailExternalLinksCollectionViewCell.self)

    func configure(
        items: [CompanyDetailExternalLinkItem],
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

    static func fittingHeight(for items: [CompanyDetailExternalLinkItem]) -> CGFloat {
        DetailExternalLinkStripCollectionViewCell.fittingHeight(
            for: items.map {
                DetailExternalLinkItem(id: $0.id, title: $0.title, url: $0.url)
            }
        )
    }
}
