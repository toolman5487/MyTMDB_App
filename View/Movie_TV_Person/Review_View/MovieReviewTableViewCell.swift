//
//  MovieReviewTableViewCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/16.
//

import Foundation
import UIKit
import Combine
import SDWebImage
import SnapKit

class MovieReviewTableViewCell: UITableViewCell {
    
    private let authorLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeFont.bold(ofSize: 16)
        return label
    }()
    
    private let authorImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.clipsToBounds = true
        image.layer.cornerRadius = 20
        return image
    }()
    
    private let ratingLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeFont.demiBold(ofSize: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let contentLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(authorImageView)
        authorImageView.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        
        contentView.addSubview(authorLabel)
        authorLabel.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(28)
            make.leading.equalTo(authorImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
        }
        
        contentView.addSubview(ratingLabel)
        ratingLabel.snp.makeConstraints { make in
            make.top.equalTo(authorImageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(ratingLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with review: Review) {
        authorLabel.text = review.author
        if let path = review.authorDetails.avatarPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w45\(path)") {
            authorImageView.sd_setImage(with: url, placeholderImage: UIImage(systemName: "person.crop.circle"))
        } else {
            authorImageView.image = UIImage(systemName: "person.crop.circle")
        }
        if let userRating = review.authorDetails.rating {
            ratingLabel.text = "Rating: \(userRating) / 10"
        } else {
            ratingLabel.text = "未評分"
        }
        contentLabel.text = review.content
    }
}
