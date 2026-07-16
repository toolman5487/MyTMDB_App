//
//  MemberSettingSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/16.
//

import SnapKit
import UIKit

// MARK: - MemberSettingSectionHeaderView

@MainActor
final class MemberSettingSectionHeaderView: UICollectionReusableView {

    // MARK: - Properties

    static let reuseIdentifier = String(describing: MemberSettingSectionHeaderView.self)

    // MARK: - UI Components

    private let titleLabel = AppFactory.Label.footnote(color: ThemeColor.textSecondary, lines: 1)

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }

    // MARK: - Configuration

    func configure(title: String?) {
        titleLabel.text = title?.uppercased()
    }

    private func configureView() {
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-4)
        }
    }
}
