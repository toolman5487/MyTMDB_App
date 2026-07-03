//
//  MainMovieListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/3.
//

import SnapKit
import UIKit

// MARK: - MainMovieListFilterHeaderView

@MainActor
final class MainMovieListFilterHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MainMovieListFilterHeaderView.self)

    // MARK: - Properties

    private var filters: [MainMovieGenreItem] = []
    var onFilterSelected: ((Int) -> Void)?
    var onShowAllFilters: (() -> Void)?

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 8
        static let itemHorizontalInset: CGFloat = 16
        static let itemHeight: CGFloat = 36
        static let buttonSize: CGFloat = 36
        static let buttonCollectionSpacing: CGFloat = 8
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
            MainMovieListFilterCollectionViewCell.self,
            forCellWithReuseIdentifier: MainMovieListFilterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    private lazy var showAllButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.up")
        configuration.baseForegroundColor = ThemeColor.textPrimary
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(handleShowAllButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Initialization

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
        filters = []
        onFilterSelected = nil
        onShowAllFilters = nil
        setShowAllButtonExpanded(false)
        collectionView.reloadData()
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = ThemeColor.background
    }

    private func setupHierarchy() {
        addSubview(collectionView)
        addSubview(showAllButton)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.leading.bottom.equalToSuperview()
            make.trailing.equalTo(showAllButton.snp.leading).offset(-Layout.buttonCollectionSpacing)
        }

        showAllButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.size.equalTo(Layout.buttonSize)
        }
    }

    // MARK: - Configuration

    func configure(filters: [MainMovieGenreItem], isExpanded: Bool) {
        self.filters = filters
        setShowAllButtonExpanded(isExpanded)
        collectionView.reloadData()

        if let selectedIndex = filters.firstIndex(where: \.isSelected) {
            collectionView.scrollToItem(
                at: IndexPath(item: selectedIndex, section: 0),
                at: .centeredHorizontally,
                animated: false
            )
        }
    }

    func setShowAllButtonExpanded(_ isExpanded: Bool) {
        showAllButton.configuration?.image = UIImage(systemName: isExpanded ? "chevron.down" : "chevron.up")
    }

    private static func filterItemSize(for title: String) -> CGSize {
        let font = UIFont.preferredFont(forTextStyle: .subheadline)
        let width = (title as NSString).size(withAttributes: [.font: font]).width
            + Layout.itemHorizontalInset * 2

        return CGSize(
            width: ceil(width),
            height: Layout.itemHeight
        )
    }

    @objc private func handleShowAllButtonTapped() {
        onShowAllFilters?()
    }
}

// MARK: - UICollectionViewDataSource

extension MainMovieListFilterHeaderView: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filters.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainMovieListFilterCollectionViewCell.reuseIdentifier,
            for: indexPath
        )
        (cell as? MainMovieListFilterCollectionViewCell)?.configure(with: filters[indexPath.item])
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension MainMovieListFilterHeaderView: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onFilterSelected?(filters[indexPath.item].id)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        Self.filterItemSize(for: filters[indexPath.item].name)
    }
}

// MARK: - MainMovieListFilterCollectionViewCell

@MainActor
private final class MainMovieListFilterCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMovieListFilterCollectionViewCell.self)

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
        titleLabel.text = nil
        containerView.backgroundColor = ThemeColor.backgroundTertiary
        containerView.layer.borderColor = UIColor.clear.cgColor
    }

    // MARK: - Configuration

    func configure(with item: MainMovieGenreItem) {
        titleLabel.text = item.name
        titleLabel.textColor = item.isSelected ? .white : ThemeColor.textPrimary
        containerView.backgroundColor = item.isSelected ? ThemeColor.primary : ThemeColor.backgroundTertiary
        containerView.layer.borderColor = borderColor(isSelected: item.isSelected).cgColor
    }

    private func borderColor(isSelected: Bool) -> UIColor {
        isSelected ? ThemeColor.highlight : ThemeColor.highlight.withAlphaComponent(0.36)
    }
}
