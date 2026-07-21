//
//  ImageTitleBaseCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - ImageTitleCellContent

nonisolated struct ImageTitleCellContent: Sendable, Equatable {
    let imageURL: URL?
    let title: String
    let subtitle: String?
    let imageHeight: CGFloat
}

// MARK: - ImageTitleBaseCollectionViewCell

@MainActor
class ImageTitleBaseCollectionViewCell: BaseCollectionViewCell {

    private enum DefaultLayout {
        static let imageHeight: CGFloat = 168
        static let imageCornerRadius: CGFloat = 8
    }

    private var imageHeight = DefaultLayout.imageHeight
    private var imageCornerRadius = DefaultLayout.imageCornerRadius
    private var imageHeightConstraint: Constraint?

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fill
        stackView.spacing = 4
        return stackView
    }()

    private let itemImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.clipsToBounds = true
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.captionPrimary(lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = AppFactory.Label.captionSecondary(color: ThemeColor.textSecondary, lines: 1)
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    override func configureView() {
        itemImageView.layer.cornerRadius = imageCornerRadius
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(itemImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(subtitleLabel)
    }

    override func setupConstraints() {
        super.setupConstraints()

        contentStackView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        itemImageView.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
            imageHeightConstraint = make.height.equalTo(imageHeight).constraint
        }

        titleLabel.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.width.equalTo(contentStackView)
        }
    }

    override func resetForReuse() {
        itemImageView.sd_cancelCurrentImageLoad()
        itemImageView.image = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
    }

    func configure(with content: ImageTitleCellContent) {
        configureLayout(imageHeight: content.imageHeight)
        configure(
            imageURL: content.imageURL,
            title: content.title,
            subtitle: content.subtitle
        )
    }

    private func configure(
        imageURL: URL?,
        title: String,
        subtitle: String?
    ) {
        itemImageView.sd_setImage(with: imageURL)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle?.isEmpty ?? true
    }

    private func configureLayout(
        imageHeight: CGFloat,
        imageCornerRadius: CGFloat = DefaultLayout.imageCornerRadius
    ) {
        self.imageHeight = imageHeight
        self.imageCornerRadius = imageCornerRadius
        imageHeightConstraint?.update(offset: imageHeight)
        itemImageView.layer.cornerRadius = imageCornerRadius
    }
}
