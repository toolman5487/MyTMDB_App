//
//  MainMemberCenterProfileCollectionViewCell.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainMemberCenterProfileCollectionViewCell

@MainActor
final class MainMemberCenterProfileCollectionViewCell: BaseCollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberCenterProfileCollectionViewCell.self)

    // MARK: - Layout

    private enum Layout {
        static let horizontalInset: CGFloat = 16
        static let verticalInset: CGFloat = 16
        static let contentSpacing: CGFloat = 16
        static let metadataSpacing: CGFloat = 6
        static let avatarSize: CGFloat = 88
        static let cornerRadius: CGFloat = 8
        static let avatarBorderWidth: CGFloat = 3
    }

    // MARK: - UI Components

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = ThemeColor.background
        imageView.tintColor = ThemeColor.textTertiary
        imageView.clipsToBounds = true
        imageView.image = UIImage(systemName: "person.crop.circle")
        return imageView
    }()

    private let displayNameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textPrimary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let localeLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private let adultContentLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = ThemeColor.textSecondary
        label.numberOfLines = 1
        return label
    }()

    private lazy var metadataStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            localeLabel,
            adultContentLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = Layout.metadataSpacing
        return stackView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            displayNameLabel,
            usernameLabel,
            metadataStackView
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 4
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            avatarImageView,
            textStackView
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.contentSpacing
        return stackView
    }()

    // MARK: - BaseCollectionViewCell

    override func configureView() {
        super.configureView()
        containerView.backgroundColor = ThemeColor.primary.withAlphaComponent(0.12)
        containerView.layer.cornerRadius = Layout.cornerRadius
        containerView.layer.cornerCurve = .continuous
        containerView.layer.masksToBounds = true
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = ThemeColor.primary.withAlphaComponent(0.18).cgColor
        avatarImageView.layer.cornerRadius = Layout.avatarSize / 2
        avatarImageView.layer.borderWidth = Layout.avatarBorderWidth
        avatarImageView.layer.borderColor = ThemeColor.background.withAlphaComponent(0.9).cgColor
    }

    override func setupHierarchy() {
        super.setupHierarchy()
        containerView.addSubview(contentStackView)
    }

    override func setupConstraints() {
        super.setupConstraints()

        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(Layout.avatarSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: Layout.verticalInset,
                    left: Layout.horizontalInset,
                    bottom: Layout.verticalInset,
                    right: Layout.horizontalInset
                )
            )
        }
    }

    override func resetForReuse() {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = UIImage(systemName: "person.crop.circle")
        displayNameLabel.text = nil
        usernameLabel.text = nil
        localeLabel.text = nil
        adultContentLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with profile: MainMemberCenterProfile) {
        avatarImageView.sd_setImage(
            with: profile.avatarURL,
            placeholderImage: UIImage(systemName: "person.crop.circle")
        )
        displayNameLabel.text = profile.displayName
        usernameLabel.text = "@\(profile.username)"
        localeLabel.text = "語言 \(profile.languageCode.uppercased()) · 地區 \(profile.regionCode.uppercased())"
        adultContentLabel.text = profile.includesAdultContent ? "包含成人內容" : "不包含成人內容"
    }
}
