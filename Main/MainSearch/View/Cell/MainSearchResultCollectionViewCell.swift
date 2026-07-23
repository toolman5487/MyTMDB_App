//
//  MainSearchResultCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/23.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainSearchResultCollectionViewCell

@MainActor
final class MainSearchResultCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainSearchResultCollectionViewCell.self)

    // MARK: - Constants

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 8
        static let contentSpacing: CGFloat = 12
        static let labelSpacing: CGFloat = 4
        static let thumbnailWidth: CGFloat = 64
        static let cornerRadius: CGFloat = 8
        static let chevronSize: CGFloat = 16
    }

    // MARK: - UI Components

    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = ThemeColor.fillSecondary
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = Layout.cornerRadius
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = AppFactory.Label.body(color: ThemeColor.textPrimary, lines: 2)
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }()

    private let subtitleLabel = AppFactory.Label.captionSecondary(
        color: ThemeColor.textSecondary,
        lines: 2
    )

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "chevron.right"))
        imageView.tintColor = ThemeColor.textTertiary
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.separator
        return view
    }()

    // MARK: - BaseCollectionViewCell

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(thumbnailImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(chevronImageView)
        containerView.addSubview(separatorView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        thumbnailImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(Layout.horizontalInset)
            make.top.bottom.equalToSuperview().inset(Layout.verticalInset)
            make.width.equalTo(Layout.thumbnailWidth)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(Layout.horizontalInset)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(Layout.chevronSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(thumbnailImageView.snp.trailing).offset(Layout.contentSpacing)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-Layout.contentSpacing)
            make.bottom.equalTo(containerView.snp.centerY).offset(-Layout.labelSpacing / 2)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalTo(titleLabel)
            make.top.equalTo(containerView.snp.centerY).offset(Layout.labelSpacing / 2)
        }

        separatorView.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.bottom.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
        }
    }

    override func resetForReuse() {
        thumbnailImageView.sd_cancelCurrentImageLoad()
        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = ThemeColor.fillSecondary
        titleLabel.text = nil
        subtitleLabel.text = nil
        subtitleLabel.isHidden = false
    }

    // MARK: - Configuration

    func configure(with item: MainSearchResultItem) {
        thumbnailImageView.image = nil
        thumbnailImageView.backgroundColor = ThemeColor.fillSecondary
        thumbnailImageView.sd_setImage(with: item.imageURL)
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        subtitleLabel.isHidden = item.subtitle?.isEmpty ?? true
    }
}
