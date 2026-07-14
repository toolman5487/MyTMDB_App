//
//  BaseShowAllFilterHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import SnapKit
import UIKit

// MARK: - BaseShowAllFilterHeaderView

@MainActor
class BaseShowAllFilterHeaderView: BaseFilterHeaderView {

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let buttonSize: CGFloat = 36
        static let buttonCollectionSpacing: CGFloat = 8
        static let showAllButtonExpandedRotation = -CGFloat.pi / 2
    }

    // MARK: - Properties

    private var isShowAllButtonExpanded = false
    var onShowAllFilters: (() -> Void)?

    // MARK: - UI Components

    private lazy var showAllButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "chevron.forward")
        configuration.baseForegroundColor = ThemeColor.textPrimary
        configuration.contentInsets = .zero
        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: #selector(handleShowAllButtonTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        onShowAllFilters = nil
        setShowAllButtonExpanded(false)
    }

    // MARK: - Setup

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

    // MARK: - Configuration

    func configure(
        filters: [BaseFilterHeaderItem],
        isExpanded: Bool,
        isShowingSkeleton: Bool = false
    ) {
        super.configure(
            filters: filters,
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

    // MARK: - Actions

    @objc private func handleShowAllButtonTapped() {
        guard !isShowingSkeleton else { return }
        onShowAllFilters?()
    }
}
