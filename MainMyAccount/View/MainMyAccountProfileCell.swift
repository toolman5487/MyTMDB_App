//
//  MainMyAccountProfileCell.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import SDWebImage
import SkeletonView
import SnapKit
import UIKit

// MARK: - MainMyAccountProfileCell

final class MainMyAccountProfileCell: MainBaseCollectionViewCell {

    // MARK: - Layout

    private enum Layout {
        static let cardRadius: CGFloat = 8
        static let avatarSize: CGFloat = 80
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 20
        static let contentSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 8
        static let chipSpacing: CGFloat = 8
        static let chipRadius: CGFloat = 8
        static let chipInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
    }

    static let height: CGFloat = Layout.verticalPadding + Layout.avatarSize + Layout.verticalPadding

    // MARK: - Content

    enum Content: Hashable {
        case skeleton
        case guest
        case profile(MainMyAccountProfileItem)
        case message(String)
    }

    // MARK: - UI Components

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.backgroundSecondary
        view.layer.cornerRadius = Layout.cardRadius
        view.layer.masksToBounds = true
        return view
    }()

    private let avatarContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemeColor.fillSecondary
        view.layer.cornerRadius = Layout.avatarSize / 2
        view.layer.masksToBounds = true
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textSecondary
        imageView.layer.cornerRadius = (Layout.avatarSize - 8) / 2
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let eyebrowLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.textSecondary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.textColor = ThemeColor.textPrimary
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let usernameLabel: PaddedLabel = {
        let label = PaddedLabel(contentInsets: Layout.chipInsets)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.textSecondary
        label.backgroundColor = ThemeColor.fillSecondary
        label.adjustsFontForContentSizeCategory = true
        label.layer.cornerRadius = Layout.chipRadius
        label.layer.masksToBounds = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return label
    }()

    private let regionChipLabel: PaddedLabel = {
        let label = PaddedLabel(contentInsets: Layout.chipInsets)
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = ThemeColor.textPrimary
        label.backgroundColor = ThemeColor.fillTertiary
        label.adjustsFontForContentSizeCategory = true
        label.layer.cornerRadius = Layout.chipRadius
        label.layer.masksToBounds = true
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private lazy var usernameRowStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [usernameLabel, regionChipLabel])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Layout.chipSpacing
        return stackView
    }()

    private lazy var titleStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [eyebrowLabel, nameLabel, usernameRowStackView])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = Layout.textSpacing
        return stackView
    }()

    override var skeletonContainerView: UIView {
        cardView
    }

    override func skeletonableSubviews() -> [UIView] {
        [
            avatarContainerView,
            eyebrowLabel,
            nameLabel,
            usernameLabel,
            regionChipLabel
        ]
    }

    // MARK: - Configuration

    func configure(with content: Content) {
        hideSkeletonAnimation(transition: .none)

        switch content {
        case .skeleton:
            configureSkeletonContent()

        case .guest:
            configureGuestContent()

        case .profile(let item):
            configureProfileContent(item)

        case .message(let message):
            configureMessageContent(message)
        }
    }

    override func resetContent() {
        hideSkeletonAnimation(transition: .none)
        setAvatarPlaceholder()
        eyebrowLabel.text = nil
        nameLabel.text = nil
        usernameLabel.text = nil
        regionChipLabel.text = nil
        setRegionChipVisible(true)
        usernameLabel.isHidden = false
    }

    // MARK: - Content States

    private func configureSkeletonContent() {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.image = nil

        eyebrowLabel.text = " "
        nameLabel.text = " "
        usernameLabel.text = " "
        regionChipLabel.text = " "
        setRegionChipVisible(true)

        nameLabel.linesCornerRadius = 8
        nameLabel.skeletonTextLineHeight = .fixed(28)
        nameLabel.skeletonTextNumberOfLines = 1

        showSkeletonAnimation()
    }

    private func configureGuestContent() {
        eyebrowLabel.text = "訪客模式"
        nameLabel.text = "先探索電影宇宙"
        usernameLabel.text = "未登入"
        regionChipLabel.text = "可瀏覽公開內容"
        setRegionChipVisible(true)
        setAvatarPlaceholder(systemName: "person.badge.questionmark")
    }

    private func configureProfileContent(_ item: MainMyAccountProfileItem) {
        eyebrowLabel.text = "註冊會員"
        nameLabel.text = item.displayName
        usernameLabel.text = "@\(item.username)"
        regionChipLabel.text = item.regionDescription
        setRegionChipVisible(true)
        loadAvatar(from: item.avatarURL)
    }

    private func configureMessageContent(_ message: String) {
        eyebrowLabel.text = "資料載入失敗"
        nameLabel.text = "暫時無法取得帳號"
        usernameLabel.text = message
        setRegionChipVisible(false)
        setAvatarPlaceholder(systemName: "exclamationmark.circle.fill", tintColor: ThemeColor.systemOrange)
    }

    // MARK: - Avatar

    private func loadAvatar(from url: URL?) {
        switch url {
        case let avatarURL?:
            avatarImageView.sd_cancelCurrentImageLoad()
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.tintColor = ThemeColor.textSecondary
            avatarImageView.image = nil
            avatarImageView.sd_setImage(with: avatarURL) { [weak self] image, _, _, _ in
                guard let self else { return }
                if image == nil {
                    self.setAvatarPlaceholder()
                }
            }

        case nil:
            setAvatarPlaceholder()
        }
    }

    private func setAvatarPlaceholder(
        systemName: String = "person.fill",
        tintColor: UIColor = ThemeColor.textSecondary
    ) {
        avatarImageView.sd_cancelCurrentImageLoad()
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.tintColor = tintColor
        avatarImageView.image = UIImage(systemName: systemName)
    }

    private func setRegionChipVisible(_ isVisible: Bool) {
        regionChipLabel.isHidden = !isVisible
    }

    // MARK: - Setup

    override func configureView() {
        super.configureView()
        cardView.isSkeletonable = true
    }

    override func setupHierarchy() {
        contentView.addSubview(cardView)
        cardView.addSubview(avatarContainerView)
        avatarContainerView.addSubview(avatarImageView)
        cardView.addSubview(titleStackView)
    }

    override func setupConstraints() {
        cardView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        avatarContainerView.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.verticalPadding)
            make.leading.equalToSuperview().inset(Layout.horizontalPadding)
            make.size.equalTo(Layout.avatarSize)
            make.bottom.equalToSuperview().inset(Layout.verticalPadding)
        }

        avatarImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(4)
        }

        titleStackView.snp.makeConstraints { make in
            make.top.equalTo(avatarContainerView)
            make.leading.equalTo(avatarContainerView.snp.trailing).offset(Layout.contentSpacing)
            make.trailing.equalToSuperview().inset(Layout.horizontalPadding)
        }
    }
}

// MARK: - PaddedLabel

@MainActor
private final class PaddedLabel: UILabel {
    private let contentInsets: UIEdgeInsets

    init(contentInsets: UIEdgeInsets) {
        self.contentInsets = contentInsets
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        self.contentInsets = .zero
        super.init(coder: coder)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}
