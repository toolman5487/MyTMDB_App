//
//  MainHomeSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SnapKit
import UIKit

// MARK: - MainHomeSectionHeaderView

@MainActor
final class MainHomeSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = String(describing: MainHomeSectionHeaderView.self)
    static let standardHeight: CGFloat = 32
    private static let titleTrailingSymbolName = "chevron.right.2"

    // MARK: - Properties

    var onTitleTapped: (() -> Void)?

    // MARK: - UI Components

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.highlight
        label.numberOfLines = 1
        return label
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        )
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        isUserInteractionEnabled = true
        addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(handleTitleTap))
        )
        backgroundColor = .clear
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16))
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        titleLabel.attributedText = nil
        onTitleTapped = nil
    }

    func configure(title: String?) {
        let font = titleLabel.font ?? .preferredFont(forTextStyle: .title3)
        titleLabel.attributedText = MainHomeSectionTitleAttributedStringFactory.make(
            title: title,
            trailingImage: Self.makeTitleTrailingImage(font: font),
            font: font,
            textColor: ThemeColor.highlight
        )
    }

    private static func makeTitleTrailingImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: titleTrailingSymbolName,
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    @objc private func handleTitleTap() {
        onTitleTapped?()
    }
}
