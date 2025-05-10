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
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 24)
        label.textColor = .label
        label.text = "我的最愛電影"
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayout()
    }
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 200, height: 300)
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
            make.top.equalToSuperview()
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
        print("Carousel update：", movies.map(\.title))
        collectionView.reloadData()
    }
}

extension FavoriteMoviesCarouselView: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("numberOfItemsInSection:", movies.count)
        return movies.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "FavoriteMovieCardCell",
                for: indexPath
              ) as? FavoriteMovieCardCell else {
            return UICollectionViewCell()
        }
        let movie = movies[indexPath.item]
        cell.configure(with: movie)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        didSelectMovie?(movies[indexPath.item])
    }
}
