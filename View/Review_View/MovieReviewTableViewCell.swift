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
    private let contentLabel:UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(authorLabel)
        contentView.addSubview(contentLabel)
        
        authorLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(authorLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with review: Review) {
        authorLabel.text = review.author
        print("Author:\(review.author)")
        contentLabel.text = review.content
    }
}
