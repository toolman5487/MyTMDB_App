//
//  MainBaseViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SnapKit
import UIKit

class MainBaseViewController: BaseViewController {

    // MARK: - UI Components

    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
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
}
