//
//  TVDetailReviewViews.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/2.
//

import SnapKit
import UIKit

// MARK: - TVDetailReviewFilterHeaderView

@MainActor
final class TVDetailReviewFilterHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailReviewFilterHeaderView.self)

    // MARK: - Properties

    private var filters: [TVDetailReviewFilterItem] = []
    var onFilterSelected: ((TVDetailReviewFilter) -> Void)?

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHorizontalInset: CGFloat = 16
        static let itemHeight: CGFloat = 36
    }

    // MARK: - UI Components

    private let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(
            top: 0,
            left: Layout.horizontalInset,
            bottom: 0,
            right: Layout.horizontalInset
        )
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceHorizontal = true
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            TVDetailReviewFilterCollectionViewCell.self,
            forCellWithReuseIdentifier: TVDetailReviewFilterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    // MARK: - Initialization

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
        filters = []
        onFilterSelected = nil
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(collectionView)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(filters: [TVDetailReviewFilterItem]) {
        self.filters = filters
        collectionView.reloadData()
    }

    fileprivate static func filterItemSize(for title: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let width = (title as NSString).size(withAttributes: [.font: font]).width
            + Layout.itemHorizontalInset * 2

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }
}

// MARK: - UICollectionViewDataSource

extension TVDetailReviewFilterHeaderView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TVDetailReviewFilterCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? TVDetailReviewFilterCollectionViewCell)?.configure(with: filters[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TVDetailReviewFilterHeaderView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onFilterSelected?(filters[indexPath.item].id)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        Self.filterItemSize(for: filters[indexPath.item].title)
    }
}

// MARK: - TVDetailReviewFilterCollectionViewCell

@MainActor
private final class TVDetailReviewFilterCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailReviewFilterCollectionViewCell.self)

    // MARK: - Properties

    private var item: TVDetailReviewFilterItem?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.layer.cornerRadius = 18
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 2
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(titleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: 0,
                    left: 16,
                    bottom: 0,
                    right: 16
                )
            )
        }
    }

    override func resetForReuse() {
        item = nil
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Configuration

    func configure(with item: TVDetailReviewFilterItem) {
        self.item = item
        titleLabel.text = item.title
        titleLabel.textColor = item.isSelected ? .white : ThemeColor.textPrimary
        containerView.backgroundColor = item.isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        containerView.layer.borderColor = borderColor(isSelected: item.isSelected).cgColor
    }

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
    }
}

// MARK: - TVDetailReviewLoadingFooterView

@MainActor
final class TVDetailReviewLoadingFooterView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailReviewLoadingFooterView.self)

    // MARK: - UI Components

    private let indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(style: .medium)
        indicatorView.color = ThemeColor.primary
        indicatorView.hidesWhenStopped = true
        return indicatorView
    }()

    // MARK: - Initialization

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
        indicatorView.stopAnimating()
    }

    // MARK: - Setup

    private func setupHierarchy() {
        addSubview(indicatorView)
    }

    private func setupConstraints() {
        indicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(isAnimating: Bool) {
        if isAnimating {
            indicatorView.startAnimating()
        } else {
            indicatorView.stopAnimating()
        }
    }
}

// MARK: - TVDetailReviewCollectionViewCell

@MainActor
final class TVDetailReviewCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: TVDetailReviewCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let rowSpacing: CGFloat = 8
        static let metadataSpacing: CGFloat = 8
        static let maxContentLineCount = 3
    }

    // MARK: - UI Components

    private let authorLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

    private let ratingLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.highlight
        label.numberOfLines = 1
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.textAlignment = .right
        label.numberOfLines = 1
        return label
    }()

    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = Layout.maxContentLineCount
        return label
    }()

    private lazy var metadataStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            ratingLabel,
            dateLabel
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.metadataSpacing
        return stackView
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            authorLabel,
            metadataStackView,
            contentLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = Layout.rowSpacing
        return stackView
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.backgroundColor = ThemeColor.backgroundSecondary
        containerView.layer.cornerRadius = 8
        containerView.layer.masksToBounds = true
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(stackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Layout.verticalInset,
                    left: Layout.horizontalInset,
                    bottom: Layout.verticalInset,
                    right: Layout.horizontalInset
                )
            )
        }
    }

    override func resetForReuse() {
        authorLabel.text = nil
        ratingLabel.text = nil
        dateLabel.text = nil
        contentLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with item: TVReviewDetailItem) {
        authorLabel.text = item.authorText.isEmpty ? "匿名使用者" : item.authorText
        ratingLabel.text = item.ratingText.map { "評分 \($0)" }
        ratingLabel.isHidden = item.ratingText == nil
        dateLabel.text = item.updatedDateText
        dateLabel.isHidden = item.updatedDateText == nil
        metadataStackView.isHidden = ratingLabel.isHidden && dateLabel.isHidden
        contentLabel.text = item.content
    }

    static func fittingHeight(for item: TVReviewDetailItem, width: CGFloat) -> CGFloat {
        let contentWidth = max(width - Layout.horizontalInset * 2, 0)
        let authorHeight = UIFont.preferredFont(forTextStyle: .headline).lineHeight
        let metadataHeight = metadataHeight(for: item)
        let contentHeight = contentHeight(for: item.content, width: contentWidth)
        let metadataSpacing = metadataHeight == 0 ? 0 : Layout.rowSpacing

        return Layout.verticalInset * 2
            + authorHeight
            + metadataSpacing
            + metadataHeight
            + Layout.rowSpacing
            + contentHeight
    }

    private static func metadataHeight(for item: TVReviewDetailItem) -> CGFloat {
        guard item.ratingText != nil || item.updatedDateText != nil else { return 0 }
        return UIFont.preferredFont(forTextStyle: .subheadline).lineHeight
    }

    private static func contentHeight(for text: String, width: CGFloat) -> CGFloat {
        guard !text.isEmpty, width > 0 else { return 0 }

        let font = UIFont.preferredFont(forTextStyle: .body)
        let maxHeight = font.lineHeight * CGFloat(Layout.maxContentLineCount)
        let boundingSize = CGSize(width: width, height: .greatestFiniteMagnitude)
        let height = (text as NSString).boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        ).height

        return min(ceil(height), ceil(maxHeight))
    }
}
