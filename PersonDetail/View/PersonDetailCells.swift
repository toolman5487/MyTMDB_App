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

    private let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFontMetrics(forTextStyle: .title1).scaledFont(
            for: .systemFont(ofSize: 28, weight: .bold)
        )
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.72
        return label
    }()

    private let metadataLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 2
        return label
    }()

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

    func configure(with item: PersonDetailHeroItem) {
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
        profileImageView.sd_cancelCurrentImageLoad()
        profileImageView.image = nil
        nameLabel.text = nil
        metadataLabel.text = nil
        metadataLabel.isHidden = false
    }
}

// MARK: - PersonDetailSectionHeaderView

@MainActor
final class PersonDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: PersonDetailSectionHeaderView.self)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
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

    private let biographyLabel: UILabel = {
        let label = UILabel()
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
final class PersonDetailFactsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailFactsCollectionViewCell.self)

    private enum Layout {
        static let itemHeight: CGFloat = 96
    }

    private var facts: [PersonDetailFactItem] = []
    private var previousCollectionWidth: CGFloat = 0

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PersonDetailFactCardCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailFactCardCollectionViewCell.reuseIdentifier
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

    func configure(facts: [PersonDetailFactItem]) {
        self.facts = facts
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }
}

extension PersonDetailFactsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        facts.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PersonDetailFactCardCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? PersonDetailFactCardCollectionViewCell {
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

        return PersonDetailFactCardCollectionViewCell.fittingSize(
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
private final class PersonDetailFactCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailFactCardCollectionViewCell.self)

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

    func configure(with item: PersonDetailFactItem) {
        titleLabel.text = item.title
        valueLabel.text = item.value
    }

    static func fittingSize(
        for item: PersonDetailFactItem,
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

// MARK: - Horizontal Image Sections

@MainActor
final class PersonDetailCreditsCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailCreditsCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [PersonDetailCreditItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PersonDetailCreditPosterCell.self,
            forCellWithReuseIdentifier: PersonDetailCreditPosterCell.reuseIdentifier
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

    func configure(items: [PersonDetailCreditItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension PersonDetailCreditsCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PersonDetailCreditPosterCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? PersonDetailCreditPosterCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

@MainActor
private final class PersonDetailCreditPosterCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailCreditPosterCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(imageHeight: 168)
    }

    func configure(with item: PersonDetailCreditItem) {
        configure(
            imageURL: item.posterURL,
            title: item.title,
            subtitle: makeSubtitle(for: item)
        )
    }

    private func makeSubtitle(for item: PersonDetailCreditItem) -> String? {
        let values = [
            item.dateText,
            item.subtitle
        ].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return values.isEmpty ? nil : values.joined(separator: " · ")
    }
}

@MainActor
final class PersonDetailProfileImagesCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailProfileImagesCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 124, height: 220)
    }

    private var items: [PersonDetailProfileImageItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PersonDetailProfileImageCell.self,
            forCellWithReuseIdentifier: PersonDetailProfileImageCell.reuseIdentifier
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

    func configure(items: [PersonDetailProfileImageItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension PersonDetailProfileImagesCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PersonDetailProfileImageCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? PersonDetailProfileImageCell {
            cell.configure(with: items[indexPath.item])
        }

        return cell
    }
}

@MainActor
private final class PersonDetailProfileImageCell: ImageTitleBaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailProfileImageCell.self)

    override func configureView() {
        super.configureView()
        configureLayout(imageHeight: 168)
    }

    func configure(with item: PersonDetailProfileImageItem) {
        configure(
            imageURL: item.imageURL,
            title: item.sizeText.isEmpty ? "人物照片" : item.sizeText,
            subtitle: nil
        )
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

    private static var titleFont: UIFont {
        .preferredFont(forTextStyle: .callout)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = titleFont
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

    func configure(with item: PersonDetailAliasItem) {
        titleLabel.text = item.name
    }

    static func fittingSize(
        for item: PersonDetailAliasItem,
        height: CGFloat,
        maximumWidth: CGFloat
    ) -> CGSize {
        let measuredWidth = (item.name as NSString).size(withAttributes: [.font: titleFont]).width
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
final class PersonDetailExternalLinksCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailExternalLinksCollectionViewCell.self)

    private enum Layout {
        static let itemSize = CGSize(width: 196, height: 96)
        static let sectionHeight: CGFloat = 96
    }

    private var items: [PersonDetailExternalLinkItem] = []
    var onLinkSelected: ((URL) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.minimumInteritemSpacing = 8
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            PersonDetailExternalLinkCollectionViewCell.self,
            forCellWithReuseIdentifier: PersonDetailExternalLinkCollectionViewCell.reuseIdentifier
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
        items: [PersonDetailExternalLinkItem],
        onLinkSelected: @escaping (URL) -> Void
    ) {
        self.items = items
        self.onLinkSelected = onLinkSelected
        collectionView.reloadData()
    }

    static func fittingHeight(for items: [PersonDetailExternalLinkItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return Layout.sectionHeight
    }
}

extension PersonDetailExternalLinksCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PersonDetailExternalLinkCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? PersonDetailExternalLinkCollectionViewCell {
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
private final class PersonDetailExternalLinkCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: PersonDetailExternalLinkCollectionViewCell.self)

    private enum Layout {
        static let iconContainerSize: CGFloat = 36
        static let iconSize: CGFloat = 18
        static let horizontalInset: CGFloat = 12
        static let contentSpacing: CGFloat = 12
        static let textSpacing: CGFloat = 4
        static let arrowSize: CGFloat = 16
    }

    private let iconContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.iconContainerSize / 2
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
        label.font = .preferredFont(forTextStyle: .callout)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingMiddle
        return label
    }()

    private let arrowImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "arrow.up.forward"))
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        return imageView
    }()

    func configure(with item: PersonDetailExternalLinkItem) {
        let style = PersonDetailExternalLinkStyle(id: item.id)
        iconImageView.image = UIImage(systemName: style.symbolName)
        iconImageView.tintColor = style.tintColor
        iconContainerView.backgroundColor = style.tintColor.withAlphaComponent(0.16)
        titleLabel.text = item.title
        valueLabel.text = displayValue(for: item)
    }

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.layer.borderColor = ThemeColor.separator.withAlphaComponent(0.36).cgColor
        containerView.layer.borderWidth = 1
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(iconContainerView)
        iconContainerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(valueLabel)
        containerView.addSubview(arrowImageView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        iconContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.iconContainerSize)
        }

        iconImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(Layout.iconSize)
        }

        arrowImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.arrowSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconContainerView.snp.trailing).offset(Layout.contentSpacing)
            make.trailing.equalTo(arrowImageView.snp.leading).offset(-Layout.contentSpacing)
            make.bottom.equalTo(containerView.snp.centerY).offset(-Layout.textSpacing / 2)
        }

        valueLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(containerView.snp.centerY).offset(Layout.textSpacing / 2)
        }
    }

    override func resetForReuse() {
        iconImageView.image = nil
        iconImageView.tintColor = nil
        iconContainerView.backgroundColor = nil
        titleLabel.text = nil
        valueLabel.text = nil
    }

    private func displayValue(for item: PersonDetailExternalLinkItem) -> String {
        switch item.id {
        case "homepage":
            return item.url.host ?? item.value

        default:
            return item.value
        }
    }
}

private struct PersonDetailExternalLinkStyle {
    let symbolName: String
    let tintColor: UIColor

    init(id: String) {
        switch id {
        case "homepage":
            self.symbolName = "link"
            self.tintColor = ThemeColor.systemBlue

        case "imdb":
            self.symbolName = "film"
            self.tintColor = ThemeColor.spotlightGold

        case "instagram":
            self.symbolName = "camera"
            self.tintColor = ThemeColor.systemPink

        case "twitter":
            self.symbolName = "bubble.left.and.bubble.right"
            self.tintColor = ThemeColor.textPrimary

        case "facebook":
            self.symbolName = "f.circle"
            self.tintColor = ThemeColor.systemBlue

        case "tiktok":
            self.symbolName = "music.note"
            self.tintColor = ThemeColor.textPrimary

        case "youtube":
            self.symbolName = "play.rectangle"
            self.tintColor = ThemeColor.systemRed

        case "wikidata":
            self.symbolName = "book"
            self.tintColor = ThemeColor.systemGreen

        default:
            self.symbolName = "arrow.up.forward.app"
            self.tintColor = ThemeColor.primary
        }
    }
}
