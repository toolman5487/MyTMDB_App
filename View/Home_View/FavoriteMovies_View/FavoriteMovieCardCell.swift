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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        posterImageView.contentMode = .scaleAspectFit
        posterImageView.image = nil
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.cornerRadius = 10
        image.layer.masksToBounds = true
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
        posterImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(180)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(posterImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        contentView.addSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(4)
        }
    }

    func favoriteMovievConfigure(with item: FavoriteMovieItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.releaseDate?
            .split(separator: "-")
            .first
            .map(String.init)
        posterImageView.contentMode = .scaleAspectFit
        if let path = item.posterPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w342\(path)") {
            posterImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "film"))
        } else {
            posterImageView.image = UIImage(systemName: "film")
        }
    }

    func configureEmptyState() {
        titleLabel.text = ""
        subtitleLabel.text = ""
        posterImageView.image = UIImage(systemName: "plus")
        posterImageView.tintColor = .label
        posterImageView.contentMode = .center
    }
}
