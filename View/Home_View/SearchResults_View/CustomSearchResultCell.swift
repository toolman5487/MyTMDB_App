//
//  CustomSearchResultCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import UIKit
import SDWebImage
import SnapKit

class SearchResultCell: UITableViewCell {
    static let reuseIdentifier = "SearchResultCell"

    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)

        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(60)
        }

        titleLabel.numberOfLines = 2
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalTo(thumbnailImageView)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: MultiSearchResult) {
        titleLabel.text = item.mediaType == .movie ? item.title : item.name
        if let path = item.posterPath ?? item.profilePath {
            let url = URL(string: "https://image.tmdb.org/t/p/w154\(path)")
            thumbnailImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "photo"))
        } else {
            thumbnailImageView.image = UIImage(systemName: "photo")
        }
    }
}
