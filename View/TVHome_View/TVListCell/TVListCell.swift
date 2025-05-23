//
//  TVListView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/23.
//

import Foundation
import UIKit
import SnapKit

class TVListCell: UITableViewCell {
    
    static let reuseIdentifier = "TVListCell"
    
    private let posterImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFill
        image.image = UIImage(systemName: "photo")
        image.clipsToBounds = true
        image.layer.cornerRadius = 10
        return image
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Title"
        label.font = ThemeFont.demiBold(ofSize: 16)
        label.numberOfLines = 2
        return label
    }()
    
    private let releaseDateLabel: UILabel = {
        let label = UILabel()
        label.text = "Release Date"
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .tertiaryLabel
        label.numberOfLines = 1
        return label
    }()

    private let overviewLabel: UILabel = {
        let label = UILabel()
        label.text = "Overview"
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .secondaryLabel
        label.numberOfLines = 6
        return label
    }()
    
    private func layout() {
        contentView.addSubview(posterImageView)
        posterImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(8)
            make.width.equalTo(80)
            make.height.equalTo(120)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(posterImageView.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(16)
            make.top.equalTo(posterImageView)
        }
        
        contentView.addSubview(releaseDateLabel)
        releaseDateLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
        
        contentView.addSubview(overviewLabel)
        overviewLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(releaseDateLabel.snp.bottom).offset(4)
            make.bottom.lessThanOrEqualToSuperview().inset(8)
        }
    }
    
    func tvCellConfigure(with tv: TVListShow) {
        posterImageView.sd_setImage(with: tv.posterURL)
        titleLabel.text = tv.name
        let dateText = tv.firstAirDate.isEmpty ? "目前無資料" : tv.firstAirDate
        releaseDateLabel.text = dateText
        let overviewText = tv.overview.isEmpty ? "目前無劇情介紹" : tv.overview
        overviewLabel.text = overviewText
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        layout()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layout()
    }
}
