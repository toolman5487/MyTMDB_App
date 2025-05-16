//
//  FavoriteMoviesCarouselView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/05/10.
//

import UIKit
import SnapKit
import SDWebImage


class FavoriteMoviesCarouselView: UIView {
    
    private var movies: [FavoriteMovieItem] = []
    var didSelectMovie: ((FavoriteMovieItem) -> Void)?
    
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
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 24)
        label.textColor = .label
        label.text = "我的最愛電影"
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
        collection.register(FavoriteMovieCardCell.self, forCellWithReuseIdentifier: "FavoriteMovieCardCell")
        
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    
    private func setupLayout() {
        addSubview(headerLabel)
        addSubview(collectionView)
        headerLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
    }
    
    func update(with movies: [FavoriteMovieItem]) {
        self.movies = movies
        collectionView.reloadData()
    }
}

extension FavoriteMoviesCarouselView: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.isEmpty ? 1 : movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteMovieCardCell", for: indexPath) as! FavoriteMovieCardCell
        if movies.isEmpty {
            cell.configureEmptyState()
        } else {
            let movie = movies[indexPath.item]
            cell.favoriteMovievConfigure(with: movie)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let maybeMovie = movies.indices.contains(indexPath.item) ? movies[indexPath.item] : nil
        if let movie = maybeMovie {
            didSelectMovie?(movie)
        }
    }
}
