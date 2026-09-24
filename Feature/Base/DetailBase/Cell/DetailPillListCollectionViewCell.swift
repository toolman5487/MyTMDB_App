//
//  DetailPillListCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import SnapKit
import UIKit

// MARK: - DetailPillListCollectionViewCell

@MainActor
class DetailPillListCollectionViewCell: BaseNestedCollectionViewCell {

    private enum Layout {
        static let minimumItemHeight: CGFloat = 44
        static let verticalInset: CGFloat = 8

        static var itemHeight: CGFloat {
            max(
                minimumItemHeight,
                ceil(UIFont.preferredFont(forTextStyle: .callout).lineHeight) + (verticalInset * 2)
            )
        }

        static var sectionHeight: CGFloat {
            itemHeight
        }
    }

    private var items: [DetailPillItem] = []
    private var itemAccessibilityLabel: String?
    private var interfaceLocalization = AppInterfaceLocalization.traditionalChinese

    override func configureView() {
        containerView.backgroundColor = .clear
        collectionViewFlowLayout.sectionInset = DetailLayoutMetrics.horizontalContentInsets
        collectionViewFlowLayout.minimumLineSpacing = 8
        collectionViewFlowLayout.minimumInteritemSpacing = 8
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            DetailPillCardCollectionViewCell.self,
            forCellWithReuseIdentifier: DetailPillCardCollectionViewCell.reuseIdentifier
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
        itemAccessibilityLabel = nil
        collectionView.reloadData()
    }

    func configure(
        items: [DetailPillItem],
        itemAccessibilityLabel: String? = nil,
        localization: AppInterfaceLocalization
    ) {
        self.items = items
        self.itemAccessibilityLabel = itemAccessibilityLabel
        interfaceLocalization = localization
        collectionViewFlowLayout.invalidateLayout()
        collectionView.reloadData()
    }

    static func fittingHeight(for items: [DetailPillItem]) -> CGFloat {
        guard !items.isEmpty else { return 0 }
        return Layout.sectionHeight
    }
}

extension DetailPillListCollectionViewCell: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: DetailPillCardCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? DetailPillCardCollectionViewCell {
            cell.configure(
                with: items[indexPath.item],
                accessibilityLabel: itemAccessibilityLabel,
                localization: interfaceLocalization
            )
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

        return DetailPillCardCollectionViewCell.fittingSize(
            for: items[indexPath.item],
            height: Layout.itemHeight,
            maximumWidth: max(collectionView.bounds.width - 32, 64)
        )
    }
}

// MARK: - DetailPillCardCollectionViewCell

@MainActor
private final class DetailPillCardCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: DetailPillCardCollectionViewCell.self)

    private enum Layout {
        static let minimumHeight: CGFloat = 44
        static let minimumWidth: CGFloat = 64
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8

        static var height: CGFloat {
            max(
                minimumHeight,
                ceil(UIFont.preferredFont(forTextStyle: .callout).lineHeight) + (verticalInset * 2)
            )
        }
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
        titleLabel.isAccessibilityElement = false
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

    func configure(
        with item: DetailPillItem,
        accessibilityLabel: String?,
        localization: AppInterfaceLocalization
    ) {
        titleLabel.text = item.title
        applyAccessibility(
            accessibilityLabel.map {
                AccessibilityText(label: $0, value: item.title)
            } ?? AccessibilityText(label: item.title)
        )
    }

    static func fittingSize(
        for item: DetailPillItem,
        height: CGFloat,
        maximumWidth: CGFloat
    ) -> CGSize {
        let measuredWidth = (item.title as NSString).size(
            withAttributes: [.font: UIFont.preferredFont(forTextStyle: .callout)]
        ).width
        let fittingWidth = ceil(measuredWidth) + (Layout.horizontalInset * 2)
        let width = min(
            max(Layout.minimumWidth, fittingWidth),
            max(Layout.minimumWidth, maximumWidth)
        )

        return CGSize(width: width, height: max(height, Layout.height))
    }
}
