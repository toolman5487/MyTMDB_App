//
//  PersonDetailCells.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - PersonDetailHeroHeaderView

@MainActor
final class PersonDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: PersonDetailHeroHeaderView.self)

    private enum Layout {
        static let height: CGFloat = 292
        static let contentInset: CGFloat = 16
        static let profileWidth: CGFloat = 132
        static let profileHeight: CGFloat = 198
    }

    private var profileURL: URL?
    private var onProfileImageSelected: ((URL) -> Void)?

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
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
        with item: PersonDetailHeroItem,
        onProfileImageSelected: ((URL) -> Void)? = nil
    ) {
        profileURL = item.profileURL
        self.onProfileImageSelected = onProfileImageSelected
        profileImageView.isUserInteractionEnabled = item.profileURL != nil && onProfileImageSelected != nil
        profileImageView.sd_setImage(with: item.profileURL)
        nameLabel.text = item.name
        metadataLabel.text = item.metadataText
        metadataLabel.isHidden = item.metadataText?.isEmpty != false
    }

    static func headerHeight() -> CGFloat {
        Layout.height
    }

    private func configureView() {
        backgroundColor = ThemeColor.background
    }

    private func setupHierarchy() {
        addSubview(profileImageView)
        addSubview(contentStackView)
        contentStackView.addArrangedSubview(nameLabel)
        contentStackView.addArrangedSubview(metadataLabel)
        profileImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage)))
    }

    private func setupConstraints() {
        profileImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.contentInset)
            make.bottom.equalToSuperview().inset(24)
            make.width.equalTo(Layout.profileWidth)
            make.height.equalTo(Layout.profileHeight)
        }

        contentStackView.snp.makeConstraints { make in
            make.leading.equalTo(profileImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(Layout.contentInset)
            make.centerY.equalTo(profileImageView)
        }
    }

    private func resetContent() {
        profileURL = nil
        onProfileImageSelected = nil
        profileImageView.isUserInteractionEnabled = false
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = nil
        nameLabel.text = nil
        metadataLabel.text = nil
        metadataLabel.isHidden = false
    }

    @objc
    private func didTapProfileImage() {
        guard let profileURL else { return }
        onProfileImageSelected?(profileURL)
    }
}

// MARK: - PersonDetailSectionHeaderView

@MainActor
final class PersonDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: PersonDetailSectionHeaderView.self)

    private let titleLabel = AppFactory.Label.headline()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func configure(title: String?) {
        titleLabel.text = title
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
}

// MARK: - PersonDetailBiographyCollectionViewCell

@MainActor
final class PersonDetailBiographyCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailBiographyCollectionViewCell.self)

    private enum Layout {
        static let contentInset: CGFloat = 16
        static let minimumHeight: CGFloat = 120
        static let titleContentSpacing: CGFloat = 8
    }

    private let biographyLabel = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 0)

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(biographyLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        biographyLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(Layout.contentInset)
        }
    }

    override func resetForReuse() {
        biographyLabel.attributedText = nil
    }

    func configure(biography: String) {
        biographyLabel.attributedText = Self.makeAttributedText(biography: biography)
    }

    static func fittingHeight(for biography: String, width: CGFloat) -> CGFloat {
        let contentWidth = width - (Layout.contentInset * 2)
        guard contentWidth > 0 else {
            return Layout.minimumHeight
        }

        let attributedText = makeAttributedText(biography: biography)
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

    private static func makeAttributedText(biography: String) -> NSAttributedString {
        let titleParagraphStyle = NSMutableParagraphStyle()
        titleParagraphStyle.paragraphSpacing = Layout.titleContentSpacing

        let bodyParagraphStyle = NSMutableParagraphStyle()
        bodyParagraphStyle.lineSpacing = 4

        let attributedText = NSMutableAttributedString(
            string: "人物簡介\n",
            attributes: [
                .font: UIFont.preferredFont(forTextStyle: .headline),
                .foregroundColor: ThemeColor.textPrimary,
                .paragraphStyle: titleParagraphStyle
            ]
        )
        attributedText.append(
            NSAttributedString(
                string: biography,
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

// MARK: - PersonDetailFactsCollectionViewCell

@MainActor
final class PersonDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailFactsCollectionViewCell.self)

    func configure(facts: [PersonDetailFactItem]) {
        configure(
            facts: facts.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - PersonDetailKnownForCollectionViewCell

@MainActor
final class PersonDetailKnownForCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailKnownForCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [PersonDetailCreditItem],
        onCreditSelected: @escaping (PersonDetailCreditItem) -> Void
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
            imageHeight: Layout.imageHeight
        ) { item in
            guard let credit = items.first(where: { $0.id == item.id }) else { return }
            onCreditSelected(credit)
        }
    }

    private static func makeSubtitle(for item: PersonDetailCreditItem) -> String? {
        BaseDisplayTextFormatter.metadata([
            item.dateText,
            item.subtitle
        ])
    }
}

// MARK: - PersonDetailCrewCollectionViewCell

@MainActor
final class PersonDetailCrewCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailCrewCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [PersonDetailCreditItem],
        onCreditSelected: @escaping (PersonDetailCreditItem) -> Void
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
            imageHeight: Layout.imageHeight
        ) { item in
            guard let credit = items.first(where: { $0.id == item.id }) else { return }
            onCreditSelected(credit)
        }
    }

    private static func makeSubtitle(for item: PersonDetailCreditItem) -> String? {
        BaseDisplayTextFormatter.metadata([
            item.dateText,
            item.subtitle
        ])
    }
}

// MARK: - PersonDetailProfileImagesCollectionViewCell

@MainActor
final class PersonDetailProfileImagesCollectionViewCell: DetailImageTitleStripCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailProfileImagesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
        static let imageHeight: CGFloat = 168
    }

    func configure(
        items: [PersonDetailProfileImageItem],
        onImageSelected: @escaping (URL) -> Void
    ) {
        configure(
            items: items.map {
                DetailImageTitleItem(
                    id: $0.id,
                    imageURL: $0.imageURL,
                    title: $0.sizeText.isEmpty ? "人物照片" : $0.sizeText,
                    subtitle: nil
                )
            },
            itemSize: Layout.itemSize,
            imageHeight: Layout.imageHeight
        ) { item in
            guard let imageURL = item.imageURL else { return }
            onImageSelected(imageURL)
        }
    }
}

// MARK: - PersonDetailAliasesCollectionViewCell

@MainActor
final class PersonDetailAliasesCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailAliasesCollectionViewCell.self)

    private enum Layout {
        static let itemHeight: CGFloat = 44
        static let sectionHeight: CGFloat = 44
    }

    private var items: [PersonDetailAliasItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.minimumInteritemSpacing = 8
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PersonDetailAliasPillCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailAliasPillCollectionViewCell.reuseIdentifier
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

    func configure(items: [PersonDetailAliasItem]) {
        self.items = items
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }

    static func fittingHeight(for items: [PersonDetailAliasItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return Layout.sectionHeight
    }
}

extension PersonDetailAliasesCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PersonDetailAliasPillCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? PersonDetailAliasPillCollectionViewCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard items.indices.contains(indexPath.item) else {
            return .zero
        }

        return PersonDetailAliasPillCollectionViewCell.fittingSize(
            for: items[indexPath.item],
            height: Layout.itemHeight,
            maximumWidth: max(collectionView.bounds.width - 32, 64)
        )
    }
}

@MainActor
private final class PersonDetailAliasPillCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailAliasPillCollectionViewCell.self)

    private enum Layout {
        static let height: CGFloat = 44
        static let minimumWidth: CGFloat = 64
        static let horizontalInset: CGFloat = 16
    }

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.callout(lines: 1)
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

    func configure(with item: PersonDetailAliasItem) {
        titleLabel.text = item.name
    }

    static func fittingSize(
        for item: PersonDetailAliasItem,
        height: CGFloat,
        maximumWidth: CGFloat
    ) -> CGSize {
        let measuredWidth = (item.name as NSString).size(
            withAttributes: [.font: UIFont.preferredFont(forTextStyle: .callout)]
        ).width
        let fittingWidth = ceil(measuredWidth) + (Layout.horizontalInset * 2)
        let width = min(
            max(Layout.minimumWidth, fittingWidth),
            max(Layout.minimumWidth, maximumWidth)
        )

        return CGSize(width: width, height: height)
    }
}

// MARK: - PersonDetailExternalLinksCollectionViewCell

@MainActor
final class PersonDetailExternalLinksCollectionViewCell: DetailExternalLinkStripCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailExternalLinksCollectionViewCell.self)

    func configure(
        items: [PersonDetailExternalLinkItem],
        onLinkSelected: @escaping (URL) -> Void
    ) {
        configure(
            items: items.map {
                DetailExternalLinkItem(id: $0.id, title: $0.title, url: $0.url)
            },
            onLinkSelected: onLinkSelected
        )
    }

    static func fittingHeight(for items: [PersonDetailExternalLinkItem]) -> CGFloat {
        DetailExternalLinkStripCollectionViewCell.fittingHeight(
            for: items.map {
                DetailExternalLinkItem(id: $0.id, title: $0.title, url: $0.url)
            }
        )
    }
}
