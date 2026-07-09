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
class BaseListViewController: BaseViewController {

    // MARK: - Properties

    var collectionViewItemHeight: CGFloat {
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
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        return collectionView
    }()

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
        updateCollectionViewItemSize()
    }

    private func updateCollectionViewItemSize() {
        let availableWidth = collectionView.bounds.width
        guard availableWidth > 0 else { return }

        let itemSize = CGSize(width: availableWidth, height: collectionViewItemHeight)
        guard collectionViewFlowLayout.itemSize != itemSize else { return }

        collectionViewFlowLayout.itemSize = itemSize
        collectionViewFlowLayout.invalidateLayout()
    }
}
