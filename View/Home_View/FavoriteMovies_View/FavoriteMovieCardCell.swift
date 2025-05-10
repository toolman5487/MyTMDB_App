//
//  FavoriteMovieCardCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/10.
//

import Foundation
import UIKit
import SnapKit
import SDWebImage

class FavoriteMovieCardCell: UICollectionViewCell {
    
    private let posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.cornerRadius = 20
        return image
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 16)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(posterImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
    
        posterImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(180)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(4)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: FavoriteMovieItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.releaseDate?
            .split(separator: "-")
            .first
            .map(String.init)
        if let path = item.posterPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w185\(path)") {
            posterImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "film"))
        } else {
            posterImageView.image = UIImage(systemName: "film")
        }
    }
}
