//
//  DetailExternalLinkCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SnapKit
import UIKit

// MARK: - DetailExternalLinkStripCollectionViewCell

@MainActor
class DetailExternalLinkStripCollectionViewCell: BaseNestedCollectionViewCell {

    private enum Layout {
        static let itemWidth: CGFloat = 72
        static let iconContainerSize: CGFloat = 56
        static let titleTopSpacing: CGFloat = 8
        private static let minimumSectionHeight: CGFloat = 88
        static let itemSpacing: CGFloat = 16

        static var sectionHeight: CGFloat {
            max(
                minimumSectionHeight,
                iconContainerSize + titleTopSpacing + ceil(UIFont.preferredFont(forTextStyle: .caption1).lineHeight)
            )
        }

        static var itemSize: CGSize {
            CGSize(width: itemWidth, height: sectionHeight)
        }
    }

    private var items: [DetailExternalLinkItem] = []
    private var onLinkSelected: ((URL) -> Void)?
    private var interfaceLocalization = AppInterfaceLocalization.traditionalChinese

    override func configureView() {
        containerView.backgroundColor = .clear
        isAccessibilityElement = false
        collectionView.isAccessibilityElement = false
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionViewFlowLayout.minimumLineSpacing = Layout.itemSpacing
        collectionViewFlowLayout.minimumInteritemSpacing = Layout.itemSpacing
        collectionViewFlowLayout.sectionInset = DetailLayoutMetrics.horizontalContentInsets
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            DetailExternalLinkItemCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailExternalLinkItemCollectionViewCell.reuseIdentifier
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
        items: [DetailExternalLinkItem],
        localization: AppInterfaceLocalization,
        onLinkSelected: @escaping (URL) -> Void
    ) {
        self.items = items
        self.onLinkSelected = onLinkSelected
        interfaceLocalization = localization
        collectionViewFlowLayout.itemSize = Layout.itemSize
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }

    static func fittingHeight(for items: [DetailExternalLinkItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return Layout.sectionHeight
    }
}

extension DetailExternalLinkStripCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetailExternalLinkItemCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? DetailExternalLinkItemCollectionViewCell {
            cell.configure(
                with: items[indexPath.item],
                localization: interfaceLocalization
            )
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard items.indices.contains(indexPath.item) else { return }
        onLinkSelected?(items[indexPath.item].url)
    }
}

// MARK: - DetailExternalLinkItemCollectionViewCell

@MainActor
class DetailExternalLinkItemCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailExternalLinkItemCollectionViewCell.self)

    private enum Layout {
        static let iconContainerSize: CGFloat = 56
        static let iconSize: CGFloat = 26
        static let titleTopSpacing: CGFloat = 8
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
        let label = AppFactory.Label.captionPrimary(lines: 1)
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

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

    override func configureView() {
        containerView.backgroundColor = .clear
        iconContainerView.isAccessibilityElement = false
        iconImageView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
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
        resetAccessibility()
    }

    func configure(
        with item: DetailExternalLinkItem,
        localization: AppInterfaceLocalization
    ) {
        let style = DetailExternalLinkStyle(id: item.id)

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
        applyAccessibility(
            AccessibilityText(
                label: item.title,
                hint: localization.string(
                    "detail.external_link.accessibility_hint",
                    defaultValue: "Double-tap to open the link"
                )
            )
        )
    }
}

// MARK: - DetailExternalLinkStyle

private struct DetailExternalLinkStyle {
    let imageName: String?
    let symbolName: String
    let tintColor: UIColor

    init(id: String) {
        switch id.lowercased() {
        case "homepage":
            self.imageName = nil
            self.symbolName = "link.circle.fill"
            self.tintColor = ThemeColor.systemBlue

        case "imdb":
            self.imageName = "imdb_icon"
            self.symbolName = "film.circle.fill"
            self.tintColor = ThemeColor.systemYellow

        case "instagram":
            self.imageName = "instagram_icon"
            self.symbolName = "camera.circle.fill"
            self.tintColor = ThemeColor.systemPink

        case "twitter":
            self.imageName = "twitter_icon"
            self.symbolName = "xmark.circle.fill"
            self.tintColor = ThemeColor.textPrimary

        case "facebook":
            self.imageName = "facebook_icon"
            self.symbolName = "f.circle.fill"
            self.tintColor = ThemeColor.systemBlue

        case "tiktok":
            self.imageName = "tiktok_icon"
            self.symbolName = "music.note"
            self.tintColor = ThemeColor.textPrimary

        case "youtube":
            self.imageName = "youtube_icon"
            self.symbolName = "play.circle.fill"
            self.tintColor = ThemeColor.systemRed

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
