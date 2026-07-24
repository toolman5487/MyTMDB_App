//
//  TVDetailSectionHeaderView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import SnapKit
import UIKit

// MARK: - TVDetailSectionHeaderView

@MainActor
final class TVDetailSectionHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: TVDetailSectionHeaderView.self)

    private var onTap: (() -> Void)?

    private let titleLabel = AppFactory.Label.headline()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        configure(title: nil)
    }

    func configure(title: String?, onTap: (() -> Void)? = nil) {
        self.onTap = onTap
        let font = titleLabel.font ?? UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.attributedText = BaseDisplayTextFormatter.titleAttributedText(
            title: title,
            trailingImage: onTap != nil ? makeTitleTrailingImage(font: font) : nil,
            font: font,
            textColor: ThemeColor.highlight
        )
        isUserInteractionEnabled = onTap != nil
    }

    private func configureView() {
        backgroundColor = .clear
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    private func setupHierarchy() {
        addSubview(titleLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
        }
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
