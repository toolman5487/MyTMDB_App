//
//  MainHomeContentStripCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SnapKit
import UIKit

// MARK: - MainHomeContentStripCollectionViewCell

@MainActor
class MainHomeContentStripCollectionViewCell: BaseCollectionViewCell {

    private enum Layout {
        static let posterWidth: CGFloat = 124
        static let itemHeight: CGFloat = 232
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
    }

    private var contents: [MainHomeContentItem] = []
    private var onContentSelected: ((MainHomeContentItem) -> Void)?

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
        layout.itemSize = CGSize(
            width: Layout.posterWidth,
            height: Layout.itemHeight
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
            MainHomePosterCollectionViewCell.self,
            forCellWithReuseIdentifier: MainHomePosterCollectionViewCell.reuseIdentifier
        )
        return collectionView
    }()

    override func configureView() {
        contentView.backgroundColor = .clear
        contentView.clipsToBounds = false
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
        contents = []
        onContentSelected = nil
        collectionView.setContentOffset(.zero, animated: false)
        collectionView.reloadData()
    }

    func configure(
        contents: [MainHomeContentItem],
        onContentSelected: @escaping (MainHomeContentItem) -> Void
    ) {
        self.contents = contents
        self.onContentSelected = onContentSelected
        collectionView.reloadData()
    }
}

extension MainHomeContentStripCollectionViewCell: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        contents.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: MainHomePosterCollectionViewCell.reuseIdentifier,
            for: indexPath
        )

        if let cell = cell as? MainHomePosterCollectionViewCell {
            cell.configure(with: contents[indexPath.item])
        }

        return cell
    }
}

extension MainHomeContentStripCollectionViewCell: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        onContentSelected?(contents[indexPath.item])
    }
}
