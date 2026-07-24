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
        titleLabel.attributedText = nil
    }

    func configure(title: String?) {
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            font: titleLabel.font ?? UIFont.preferredFont(forTextStyle: .headline),
            textColor: ThemeColor.highlight
        )
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
