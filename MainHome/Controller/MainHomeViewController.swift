//
//  MainHomeViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import UIKit

@MainActor
final class MainHomeViewController: MainBaseViewController {

    // MARK: - Constants

    private enum CellIdentifier {
        static let base = String(describing: BaseCollectionViewCell.self)
    }

    // MARK: - BaseViewController

    override func configureView() {
        super.configureView()
        configureCollectionView()
    }

    // MARK: - Setup

    private func configureCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(
            BaseCollectionViewCell.self,
            forCellWithReuseIdentifier: CellIdentifier.base
        )
    }
}

// MARK: - UICollectionViewDataSource

extension MainHomeViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: CellIdentifier.base,
            for: indexPath
        )
        cell.backgroundColor = ThemeColor.textPrimary
        cell.layer.cornerRadius = 16
        cell.clipsToBounds = true
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension MainHomeViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}
