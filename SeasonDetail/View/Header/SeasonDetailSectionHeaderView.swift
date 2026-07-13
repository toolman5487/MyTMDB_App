//
//  SeasonDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import SnapKit
import UIKit

// MARK: - SeasonDetailSectionHeaderView

@MainActor
final class SeasonDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: SeasonDetailSectionHeaderView.self)

    private let titleLabel = AppFactory.Label.headline()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupHierarchy()
        setupConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    func configure(title: String?) {
        titleLabel.text = title
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
}
