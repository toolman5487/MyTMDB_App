//
//  MovieDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import SnapKit
import UIKit

// MARK: - MovieDetailSectionHeaderView

@MainActor
final class MovieDetailSectionHeaderView: UICollectionReusableView {

    // MARK: - Constants

    static let reuseIdentifier = String(describing: MovieDetailSectionHeaderView.self)

    private var onTap: (() -> Void)?

    // MARK: - UI Components

    private let titleLabel = AppFactory.Label.sectionTitle()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureView()
        setupHierarchy()
        setupConstraints()
    }

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: nil)
    }

    // MARK: - Setup

    private func configureView() {
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
    }

    // MARK: - Configuration

    func configure(title: String?, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        if onTap == nil {
            titleLabel.attributedText = nil
            titleLabel.text = title
        } else {
            titleLabel.attributedText = makeTitleAttributedText(title: title)
        }
        isUserInteractionEnabled = onTap != nil
    }

    private func makeTitleAttributedText(title: String?) -> NSAttributedString? {
        let font = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .title3)
        return MainHomeSectionTitleAttributedStringFactory.make(
            title: title,
            trailingImage: makeTitleTrailingImage(font: font),
            font: font,
            textColor: titleLabel.textColor
        )
    }

    private func makeTitleTrailingImage(font: UIFont) -> UIImage? {
        UIImage(
            systemName: "chevron.right.2",
            withConfiguration: UIImage.SymbolConfiguration(font: font, scale: .small)
        )
    }

    @objc
    private func handleTap() {
        onTap?()
    }
}
