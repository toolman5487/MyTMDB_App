//
//  CategoryCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import UIKit
import SnapKit

class CategoryCell: UICollectionViewCell {

   private let titleLabel:UILabel = {
        let label = UILabel()
       label.font = ThemeFont.demiBold(ofSize: 16)
       label.textAlignment = .center
       return label
    }()
    
    func configure(text: String, selected: Bool) {
        titleLabel.text = text
        contentView.backgroundColor = selected ? .label : .secondarySystemBackground
        titleLabel.textColor = selected ? .secondarySystemBackground : .label
    }

   override init(frame: CGRect) {
       super.init(frame: frame)
       contentView.addSubview(titleLabel)
       titleLabel.snp.makeConstraints { make in
           make.edges.equalToSuperview().inset(8)
       }
       contentView.layer.cornerRadius = 16
       contentView.clipsToBounds = true
   }
    required init?(coder: NSCoder) {
        fatalError()
    }
}
