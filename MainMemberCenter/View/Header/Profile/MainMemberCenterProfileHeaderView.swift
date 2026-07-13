//
//  MainMemberCenterProfileHeaderView.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import SDWebImage
import SnapKit
import UIKit

// MARK: - MainMemberCenterProfileLayout

enum MainMemberCenterProfileLayout {
    static let verticalInset: CGFloat = 12
    static let horizontalInset: CGFloat = 16
    static let avatarSize: CGFloat = 60
    static let placeholderAvatarPointSize: CGFloat = 28
    static let contentSpacing: CGFloat = 12
    static let textSpacing: CGFloat = 2
    static let chevronSize: CGFloat = 24

    static var headerHeight: CGFloat {
        verticalInset * 2 + avatarSize
    }
}

// MARK: - MainMemberCenterProfileHeaderView

@MainActor
final class MainMemberCenterProfileHeaderView: UICollectionReusableView {

    static let reuseIdentifier = String(describing: MainMemberCenterProfileHeaderView.self)

    // MARK: - Properties

    var onTap: (() -> Void)?

    private static let placeholderAvatarImage = UIImage(
        systemName: "person.fill",
        withConfiguration: UIImage.SymbolConfiguration(
            pointSize: MainMemberCenterProfileLayout.placeholderAvatarPointSize,
            weight: .regular
        )
    )

    // MARK: - UI Components

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .center
        imageView.backgroundColor = ThemeColor.backgroundTertiary
        imageView.tintColor = ThemeColor.textTertiary
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = MainMemberCenterProfileLayout.avatarSize / 2
        imageView.layer.cornerCurve = .continuous
        imageView.image = placeholderAvatarImage
        return imageView
    }()

    private let displayNameLabel: UILabel = {
        let label = AppFactory.Label.headline()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let usernameLabel: UILabel = {
        let label = AppFactory.Label.subheadline()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let chevronImageView: UIImageView = {
        let imageView = AppFactory.ImageView.symbol(
            systemName: "chevron.right",
            pointSize: MainMemberCenterProfileLayout.chevronSize,
            color: ThemeColor.textTertiary
        )
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.required, for: .horizontal)
        return imageView
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            displayNameLabel,
            usernameLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.spacing = MainMemberCenterProfileLayout.textSpacing
        stackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            avatarImageView,
            textStackView,
            chevronImageView
        ])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = MainMemberCenterProfileLayout.contentSpacing
        return stackView
    }()

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

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.sd_cancelCurrentImageLoad()
        setPlaceholderAvatar()
        displayNameLabel.text = nil
        usernameLabel.text = nil
    }

    // MARK: - Configuration

    func configure(with content: MainMemberCenterProfileHeaderContent) {
        if let avatarImageData = content.avatarImageData,
           let image = UIImage(data: avatarImageData) {
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.image = image
            displayNameLabel.text = content.displayName
            usernameLabel.text = content.subtitle
            return
        }

        guard let avatarURL = content.avatarURL else {
            setPlaceholderAvatar()
            displayNameLabel.text = content.displayName
            usernameLabel.text = content.subtitle
            return
        }

        setPlaceholderAvatar()
        avatarImageView.sd_setImage(
            with: avatarURL,
            placeholderImage: Self.placeholderAvatarImage
        ) { [weak self] image, _, _, _ in
            guard let self else { return }

            if image == nil {
                setPlaceholderAvatar()
            } else {
                avatarImageView.contentMode = .scaleAspectFill
            }
        }
        displayNameLabel.text = content.displayName
        usernameLabel.text = content.subtitle
    }

    // MARK: - Private Methods

    private func configureView() {
        backgroundColor = ThemeColor.background
        isUserInteractionEnabled = true
        accessibilityTraits.insert(.button)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tapGesture)
    }

    private func setupHierarchy() {
        addSubview(contentStackView)
    }

    private func setupConstraints() {
        avatarImageView.snp.makeConstraints { make in
            make.size.equalTo(MainMemberCenterProfileLayout.avatarSize)
        }

        chevronImageView.snp.makeConstraints { make in
            make.size.equalTo(MainMemberCenterProfileLayout.chevronSize)
        }

        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(
                UIEdgeInsets(
                    top: MainMemberCenterProfileLayout.verticalInset,
                    left: MainMemberCenterProfileLayout.horizontalInset,
                    bottom: MainMemberCenterProfileLayout.verticalInset,
                    right: MainMemberCenterProfileLayout.horizontalInset
                )
            )
        }
    }

    private func setPlaceholderAvatar() {
        avatarImageView.contentMode = .center
        avatarImageView.image = Self.placeholderAvatarImage
    }

    @objc private func handleTap() {
        onTap?()
    }
}
