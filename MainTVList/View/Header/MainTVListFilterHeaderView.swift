//
//  MainTVListFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import UIKit

// MARK: - MainTVListFilterHeaderView

@MainActor
final class MainTVListFilterHeaderView: BaseFilterHeaderView {

    static let reuseIdentifier = String(describing: MainTVListFilterHeaderView.self)

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let buttonSize: CGFloat = 36
        static let buttonCollectionSpacing: CGFloat = 8
        static let showAllButtonExpandedRotation = -CGFloat.pi / 2
    }

    var onFilterSelected: ((Int) -> Void)?
    var onShowAllFilters: (() -> Void)?

    private var isShowAllButtonExpanded = false

    private lazy var showAllButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.forward")
        configuration.baseForegroundColor = ThemeColor.textPrimary
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(handleShowAllButtonTapped), for: .touchUpInside)
        return button
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        onFilterSelected = nil
        onShowAllFilters = nil
        setShowAllButtonExpanded(false)
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        addSubview(showAllButton)
    }

    override func setupConstraints() {
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

    func configure(
        filters: [MainTVGenreItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        onBaseFilterSelected = { [weak self] item in
            guard let id = Int(item.id) else { return }
            self?.onFilterSelected?(id)
        }

        configure(
            filters: filters.map(BaseFilterHeaderItem.init(tvGenre:)),
            isShowingSkeleton: isShowingSkeleton
        )
        showAllButton.isHidden = isShowingSkeleton
        showAllButton.isEnabled = !isShowingSkeleton
        setShowAllButtonExpanded(isExpanded)
    }

    func setShowAllButtonExpanded(_ isExpanded: Bool, animated: Bool = false) {
        let didChange = isShowAllButtonExpanded != isExpanded
        isShowAllButtonExpanded = isExpanded

        let transform: CGAffineTransform = isExpanded
            ? CGAffineTransform(rotationAngle: Layout.showAllButtonExpandedRotation)
            : .identity

        let updateTransform: () -> Void = { [weak self] in
            self?.showAllButton.imageView?.transform = transform
        }

        guard animated, didChange else {
            updateTransform()
            return
        }

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: [.curveEaseInOut, .allowUserInteraction],
            animations: updateTransform
        )
    }

    @objc private func handleShowAllButtonTapped() {
        guard !isShowingSkeleton else { return }
        onShowAllFilters?()
    }
}

// MARK: - Mapping

private extension BaseFilterHeaderItem {

    init(tvGenre: MainTVGenreItem) {
        self.init(
            id: String(tvGenre.id),
            title: tvGenre.name,
            isSelected: tvGenre.isSelected
        )
    }
}
