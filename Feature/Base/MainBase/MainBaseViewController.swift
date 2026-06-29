//
//  MainBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation
import SnapKit
import UIKit

@MainActor
class MainBaseViewController: BaseViewController {

    // MARK: - Properties

    let contentView = UIView()

    private(set) lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: makeCollectionViewLayout()
    )

    var pageTitle: String {
        ""
    }

    var largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode {
        .always
    }

    var contentInsets: UIEdgeInsets {
        .zero
    }

    private var embeddedContentView: UIView?

    // MARK: - Template Methods

    override func configureView() {
        super.configureView()
        title = pageTitle
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        configureCollectionView()
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        view.addSubview(contentView)

        if let contentView = makeContentView() {
            setContentView(contentView)
        }
    }

    override func setupConstraints() {
        super.setupConstraints()
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(contentInsets)
        }
    }

    func makeContentView() -> UIView? {
        collectionView
    }

    func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = largeTitleDisplayMode == .never ? .never : .automatic
        collectionView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 96, right: 0)
        collectionView.scrollIndicatorInsets = collectionView.contentInset
    }

    func makeCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, _ in
            self?.makeDefaultCollectionViewSectionLayout()
        }
    }

    func makeNavigationController() -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: self)
        navigationController.navigationBar.prefersLargeTitles = largeTitleDisplayMode != .never
        navigationController.view.backgroundColor = .clear
        return navigationController
    }

    func tabDidSelect() {}

    func tabDidReselect() {}

    func pageDidBecomeVisible() {}

    func pageDidEndVisible() {}

    // MARK: - Content

    func setContentView(_ newContentView: UIView) {
        embeddedContentView?.removeFromSuperview()
        embeddedContentView = newContentView

        contentView.addSubview(newContentView)
        newContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func makeDefaultCollectionViewSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(64)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(64)
        )
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
        return section
    }
}
