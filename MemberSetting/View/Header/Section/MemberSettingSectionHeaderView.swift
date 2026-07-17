//
//  MemberSettingSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/16.
//

import UIKit

// MARK: - MemberSettingSectionHeaderView

@MainActor
final class MemberSettingSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let bottomInset: CGFloat = 4
    }

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

    override func layoutSubviews() {
        super.layoutSubviews()
        let labelHeight = titleLabel.intrinsicContentSize.height
        titleLabel.frame = CGRect(
            x: Layout.horizontalInset,
            y: bounds.height - Layout.bottomInset - labelHeight,
            width: bounds.width - Layout.horizontalInset * 2,
            height: labelHeight
        )
    }

    // MARK: - Configuration

    func configure(title: String?) {
        titleLabel.text = title?.uppercased()
        setNeedsLayout()
    }

    private func configureView() {
        backgroundColor = .clear
        addSubview(titleLabel)
    }
}
