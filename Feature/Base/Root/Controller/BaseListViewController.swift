//
//  BaseListViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/9.
//

import SnapKit
import UIKit

// MARK: - BaseListViewController

@MainActor
class BaseListViewController: BaseViewController, CollectionViewItemSizingProviding {

    // MARK: - Override Points

    var fallbackCollectionViewItemHeight: CGFloat {
        80
    }

    // MARK: - UI Components

    let collectionViewFlowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        return layout
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(
            frame: .zero,
            collectionViewLayout: collectionViewFlowLayout
        )
        collectionView.backgroundColor = ThemeColor.clear
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

    // MARK: - Initialization

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        hidesBottomBarWhenPushed = true
    }

    // MARK: - BaseViewController

    override func setupHierarchy() {
        view.addSubview(collectionView)
    }

    override func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    // MARK: - Layout

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewItemSizeIfNeeded()
    }

    override func contentSizeCategoryDidChange() {
        super.contentSizeCategoryDidChange()
        updateCollectionViewItemSizeIfNeeded()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
}
