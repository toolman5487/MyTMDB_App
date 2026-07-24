//
//  OrganizationDetailViews.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/24.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - Hero

@MainActor
final class OrganizationDetailHeroHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: OrganizationDetailHeroHeaderView.self)

    private enum Layout {
        static let height: CGFloat = 244
        static let logoSize = CGSize(width: 144, height: 112)
    }

    private var logoURL: URL?
    private var onLogoSelected: ((URL) -> Void)?

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel = AppFactory.Label.title1(alignment: .natural, lines: 3)
    private let metadataLabel = AppFactory.Label.callout(lines: 2)

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        logoURL = nil
        onLogoSelected = nil
        logoImageView.isUserInteractionEnabled = false
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        nameLabel.text = nil
        metadataLabel.text = nil
        metadataLabel.isHidden = false
    }

    func configure(
        item: OrganizationDetailHeroItem,
        onLogoSelected: ((URL) -> Void)? = nil
    ) {
        logoURL = item.logoURL
        self.onLogoSelected = onLogoSelected
        logoImageView.isUserInteractionEnabled = item.logoURL != nil && onLogoSelected != nil
        logoImageView.sd_setImage(with: item.logoURL)
        nameLabel.text = item.name
        metadataLabel.text = BaseDisplayTextFormatter.metadata([
            item.kindText,
            item.countryText
        ])
        metadataLabel.isHidden = metadataLabel.text?.isEmpty != false
    }

    static var height: CGFloat {
        Layout.height
    }

    private func setupView() {
        backgroundColor = ThemeColor.background
        addSubview(logoImageView)
        addSubview(textStackView)
        textStackView.addArrangedSubview(nameLabel)
        textStackView.addArrangedSubview(metadataLabel)
        logoImageView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapLogo))
        )

        logoImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(24)
            make.size.equalTo(Layout.logoSize)
        }

        textStackView.snp.makeConstraints { make in
            make.leading.equalTo(logoImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(logoImageView)
        }
    }

    @objc
    private func didTapLogo() {
        guard let logoURL else { return }
        onLogoSelected?(logoURL)
    }
}

// MARK: - Section Header

@MainActor
final class OrganizationDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: OrganizationDetailSectionHeaderView.self)

    private let titleLabel = AppFactory.Label.headline()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func configure(title: String?) {
        titleLabel.text = title
    }
}

// MARK: - Overview

@MainActor
final class OrganizationDetailOverviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailOverviewCollectionViewCell.self)

    private enum Layout {
        static let inset: CGFloat = 16
        static let minimumHeight: CGFloat = 96
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
            make.edges.equalToSuperview().inset(Layout.inset)
        }
    }

    override func resetForReuse() {
        overviewLabel.text = nil
    }

    func configure(text: String) {
        overviewLabel.text = text
    }

    static func fittingHeight(text: String, width: CGFloat) -> CGFloat {
        let contentWidth = max(width - (Layout.inset * 2), 0)
        let size = (text as NSString).boundingRect(
            with: CGSize(width: contentWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.preferredFont(forTextStyle: .body)],
            context: nil
        )
        return max(Layout.minimumHeight, ceil(size.height) + (Layout.inset * 2))
    }
}

// MARK: - Facts

@MainActor
final class OrganizationDetailFactsCollectionViewCell: DetailFactsCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailFactsCollectionViewCell.self)

    func configure(items: [OrganizationDetailFactItem]) {
        configure(
            facts: items.map {
                DetailFactItem(title: $0.title, value: $0.value)
            }
        )
    }
}

// MARK: - Aliases

@MainActor
final class OrganizationDetailAliasesCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailAliasesCollectionViewCell.self)

    private var items: [OrganizationDetailAliasItem] = []

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionViewFlowLayout.scrollDirection = .horizontal
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionView.register(
            OrganizationDetailAliasCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailAliasCollectionViewCell.reuseIdentifier
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

    func configure(items: [OrganizationDetailAliasItem]) {
        self.items = items
        collectionView.reloadData()
    }
}

extension OrganizationDetailAliasesCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrganizationDetailAliasCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? OrganizationDetailAliasCollectionViewCell)?.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        OrganizationDetailAliasCollectionViewCell.fittingSize(item: items[indexPath.item])
    }
}

@MainActor
private final class OrganizationDetailAliasCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailAliasCollectionViewCell.self)

    private let nameLabel = AppFactory.Label.callout(lines: 1)

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(nameLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()
        nameLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
        }
    }

    override func resetForReuse() {
        nameLabel.text = nil
    }

    func configure(item: OrganizationDetailAliasItem) {
        nameLabel.text = item.name
    }

    static func fittingSize(item: OrganizationDetailAliasItem) -> CGSize {
        let width = (item.name as NSString).size(
            withAttributes: [.font: UIFont.preferredFont(forTextStyle: .callout)]
        ).width
        return CGSize(width: ceil(width) + 24, height: 44)
    }
}

// MARK: - Logos

@MainActor
final class OrganizationDetailLogosCollectionViewCell: BaseNestedCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailLogosCollectionViewCell.self)

    private var items: [OrganizationDetailLogoItem] = []
    private var onItemSelected: ((OrganizationDetailLogoItem) -> Void)?

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionViewFlowLayout.scrollDirection = .horizontal
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionView.register(
            OrganizationDetailLogoCollectionViewCell.self,
            forCellWithReuseIdentifier: OrganizationDetailLogoCollectionViewCell.reuseIdentifier
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
        items: [OrganizationDetailLogoItem],
        onItemSelected: ((OrganizationDetailLogoItem) -> Void)? = nil
    ) {
        self.items = items
        self.onItemSelected = onItemSelected
        collectionView.reloadData()
    }
}

extension OrganizationDetailLogosCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrganizationDetailLogoCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? OrganizationDetailLogoCollectionViewCell)?.configure(item: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard items.indices.contains(indexPath.item) else { return }
        onItemSelected?(items[indexPath.item])
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: 176, height: 136)
    }
}

@MainActor
private final class OrganizationDetailLogoCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailLogoCollectionViewCell.self)

    private let logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        return imageView
    }()

    private let resolutionLabel = AppFactory.Label.captionSecondary(
        color: ThemeColor.textSecondary,
        lines: 1
    )

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(logoImageView)
        containerView.addSubview(resolutionLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()
        logoImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(112)
        }
        resolutionLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview()
        }
    }

    override func resetForReuse() {
        logoImageView.sd_cancelCurrentImageLoad()
        logoImageView.image = nil
        resolutionLabel.text = nil
        resolutionLabel.isHidden = false
    }

    func configure(item: OrganizationDetailLogoItem) {
        logoImageView.sd_setImage(with: item.imageURL)
        resolutionLabel.text = item.resolutionText
        resolutionLabel.isHidden = item.resolutionText == nil
    }
}

// MARK: - Link

@MainActor
final class OrganizationDetailLinkCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: OrganizationDetailLinkCollectionViewCell.self)

    private var url: URL?
    private var onSelected: ((URL) -> Void)?

    private let titleLabel = AppFactory.Label.callout(lines: 1)
    private let valueLabel = AppFactory.Label.captionSecondary(
        color: ThemeColor.textSecondary,
        lines: 1
    )
    private let iconImageView = UIImageView(image: UIImage(systemName: "arrow.up.right"))

    private let textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
        return stackView
    }()

    override func configureView() {
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.clipsToBounds = true
        containerView.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(didTapLink))
        )
        iconImageView.tintColor = ThemeColor.highlight
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(textStackView)
        containerView.addSubview(iconImageView)
        textStackView.addArrangedSubview(titleLabel)
        textStackView.addArrangedSubview(valueLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()
        textStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.lessThanOrEqualTo(iconImageView.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
        iconImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }

    override func resetForReuse() {
        url = nil
        onSelected = nil
        titleLabel.text = nil
        valueLabel.text = nil
    }

    func configure(
        item: OrganizationDetailLinkItem,
        onSelected: ((URL) -> Void)? = nil
    ) {
        url = item.url
        self.onSelected = onSelected
        titleLabel.text = item.title
        valueLabel.text = item.value
    }

    @objc
    private func didTapLink() {
        guard let url else { return }
        onSelected?(url)
    }
}
