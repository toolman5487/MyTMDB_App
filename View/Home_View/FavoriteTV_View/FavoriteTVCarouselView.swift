//
//  FavoriteTVCarouselView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/11.
//

import Foundation
import UIKit
import SnapKit
import SDWebImage
import Combine

class FavoriteTVCarouselView:UIView{
    
    private var tvItems:[FavoriteTVItem] = []
    var didSelectTV: ((FavoriteTVItem) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        backgroundColor = .secondarySystemBackground
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
        backgroundColor = .secondarySystemBackground
    }
    
    private let tvHeaderLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 24)
        label.textColor = .label
        label.text = "我的最愛影集"
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 120, height: 300)
        layout.minimumLineSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        collection.register(FavoriteTVCardCell.self, forCellWithReuseIdentifier: "FavoriteTVCardCell")
        
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    private func setupLayout() {
        addSubview(tvHeaderLabel)
        addSubview(collectionView)
        tvHeaderLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(tvHeaderLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
    }
    
    func update(with items: [FavoriteTVItem]) {
        self.tvItems = items
        print("Carousel update：", items.map(\.name))
        collectionView.reloadData()
    }
}

extension FavoriteTVCarouselView: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("numberOfItemsInSection:", tvItems.count)
        return tvItems.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteTVCardCell", for: indexPath) as! FavoriteTVCardCell
        let tv = tvItems[indexPath.item]
        cell.favoriteTVConfigure(with: tv)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectTV?(tvItems[indexPath.item])
    }
    
}

