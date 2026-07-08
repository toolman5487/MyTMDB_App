//
//  EpisodeDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/8.
//

import SnapKit
import UIKit

// MARK: - EpisodeDetailSectionHeaderView

@MainActor
final class EpisodeDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: EpisodeDetailSectionHeaderView.self)

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        return label
    }()

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
