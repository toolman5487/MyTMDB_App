//
//  MainMemberSettingSectionCollectionViewCells.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import SDWebImage
import UIKit

// MARK: - MainMemberSettingProfileSummaryCollectionViewCell

@MainActor
final class MainMemberSettingProfileSummaryCollectionViewCell: UICollectionViewListCell {

    static let reuseIdentifier = String(describing: MainMemberSettingProfileSummaryCollectionViewCell.self)

    // MARK: - Constants

    private enum Layout {
        static let avatarSize: CGFloat = 56
        static let avatarSymbolPointSize: CGFloat = 28
        static let imageToTextPadding: CGFloat = 12
        static let rowCornerRadius: CGFloat = 12
    }

    // MARK: - Properties

    private var avatarImageOperation: SDWebImageOperation?
    private var representedAvatarURL: URL?

    // MARK: - Lifecycle

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageOperation?.cancel()
        avatarImageOperation = nil
        representedAvatarURL = nil
        contentConfiguration = nil
        backgroundConfiguration = nil
        accessories = []
        applyAccessibilityText(nil)
        accessibilityTraits = .none
    }

    // MARK: - Configuration

    func configure(with item: MainMemberSettingProfileSummaryItem) {
        representedAvatarURL = item.avatarURL
        contentConfiguration = makeContentConfiguration(
            for: item,
            avatarImage: makeAvatarImage(from: item.avatarImageData)
        )
        backgroundConfiguration = makeBackgroundConfiguration()
        accessories = [.disclosureIndicator()]
        applyAccessibilityText(item.accessibilityText)
        accessibilityTraits = .button
        loadAvatarImageIfNeeded(from: item.avatarURL)
    }

    private func makeContentConfiguration(
        for item: MainMemberSettingProfileSummaryItem,
        avatarImage: UIImage
    ) -> UIListContentConfiguration {
        var configuration = defaultContentConfiguration()
        configuration.text = item.displayName
        configuration.secondaryText = item.usernameText
        configuration.image = avatarImage
        configuration.imageToTextPadding = Layout.imageToTextPadding
        configuration.textProperties.color = ThemeColor.textPrimary
        configuration.secondaryTextProperties.color = ThemeColor.textSecondary
        return configuration
    }

    private func makeBackgroundConfiguration() -> UIBackgroundConfiguration {
        var configuration = UIBackgroundConfiguration.listCell()
        configuration.backgroundColor = .secondarySystemGroupedBackground
        configuration.cornerRadius = Layout.rowCornerRadius
        return configuration
    }

    private func loadAvatarImageIfNeeded(from avatarURL: URL?) {
        guard let avatarURL else { return }

        avatarImageOperation = SDWebImageManager.shared.loadImage(
            with: avatarURL,
            options: [],
            progress: nil
        ) { [weak self] image, _, _, _, _, imageURL in
            Task(priority: .userInitiated) { @MainActor in
                guard let self,
                      imageURL == self.representedAvatarURL,
                      let image else {
                    return
                }

                self.updateAvatarImage(image)
            }
        }
    }

    private func updateAvatarImage(_ image: UIImage) {
        guard var configuration = contentConfiguration as? UIListContentConfiguration else { return }
        configuration.image = makeAvatarImage(from: image)
        contentConfiguration = configuration
    }

    private func makeAvatarImage(from imageData: Data?) -> UIImage {
        guard let imageData,
              let image = UIImage(data: imageData) else {
            return makeAvatarImage(from: Optional<UIImage>.none)
        }

        return makeAvatarImage(from: image)
    }

    private func makeAvatarImage(from image: UIImage?) -> UIImage {
        let size = CGSize(width: Layout.avatarSize, height: Layout.avatarSize)
        let bounds = CGRect(origin: .zero, size: size)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            UIBezierPath(ovalIn: bounds).addClip()

            if let image {
                image.draw(in: bounds)
                return
            }

            ThemeColor.backgroundTertiary.setFill()
            UIBezierPath(ovalIn: bounds).fill()

            guard let symbolImage = UIImage(
                systemName: "person.fill",
                withConfiguration: UIImage.SymbolConfiguration(
                    pointSize: Layout.avatarSymbolPointSize,
                    weight: .regular
                )
            )?.withTintColor(ThemeColor.textTertiary, renderingMode: .alwaysOriginal) else {
                return
            }

            let symbolOrigin = CGPoint(
                x: (size.width - Layout.avatarSymbolPointSize) / 2,
                y: (size.height - Layout.avatarSymbolPointSize) / 2
            )
            symbolImage.draw(
                in: CGRect(
                    origin: symbolOrigin,
                    size: CGSize(width: Layout.avatarSymbolPointSize, height: Layout.avatarSymbolPointSize)
                )
            )
        }
    }
}

// MARK: - MainMemberSettingRefreshProfileCollectionViewCell

@MainActor
final class MainMemberSettingRefreshProfileCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingRefreshProfileCollectionViewCell.self)
}

// MARK: - MainMemberSettingDefaultCollectionViewCell

@MainActor
final class MainMemberSettingDefaultCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingDefaultCollectionViewCell.self)
}

// MARK: - MainMemberSettingClearProfileCacheCollectionViewCell

@MainActor
final class MainMemberSettingClearProfileCacheCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingClearProfileCacheCollectionViewCell.self)
}

// MARK: - MainMemberSettingAppVersionCollectionViewCell

@MainActor
final class MainMemberSettingAppVersionCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingAppVersionCollectionViewCell.self)
}

// MARK: - MainMemberSettingTMDBAttributionCollectionViewCell

@MainActor
final class MainMemberSettingTMDBAttributionCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingTMDBAttributionCollectionViewCell.self)
}

// MARK: - MainMemberSettingLogoutButtonCollectionViewCell

@MainActor
final class MainMemberSettingLogoutButtonCollectionViewCell: MainMemberSettingButtonCollectionViewCell {
    static let reuseIdentifier = String(describing: MainMemberSettingLogoutButtonCollectionViewCell.self)
}

// MARK: - MainMemberSettingGuestPromptCollectionViewCell

@MainActor
final class MainMemberSettingGuestPromptCollectionViewCell: UICollectionViewCell {

    static let reuseIdentifier = String(describing: MainMemberSettingGuestPromptCollectionViewCell.self)

    // MARK: - Constants

    private enum Layout {
        static let cornerRadius: CGFloat = 12
        static let contentInset: CGFloat = 24
        static let iconSize: CGFloat = 40
        static let textSpacing: CGFloat = 8
        static let actionTopSpacing: CGFloat = 16
        static let actionSpacing: CGFloat = 12
        static let actionHeight: CGFloat = 44
    }

    // MARK: - Properties

    private var onLogin: (() -> Void)?
    private var onRegister: (() -> Void)?

    // MARK: - UI Components

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ThemeColor.textTertiary
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: Layout.iconSize)
        return imageView
    }()

    private let titleLabel = AppFactory.Label.headline(alignment: .center, lines: 0)

    private let messageLabel: UILabel = {
        let label = AppFactory.Label.body(alignment: .center, lines: 0)
        label.textColor = ThemeColor.textSecondary
        return label
    }()

    private lazy var loginButton: UIButton = {
        let button = AppFactory.Button.primaryFilled(title: "")
        button.addAction(UIAction { [weak self] _ in self?.onLogin?() }, for: .touchUpInside)
        return button
    }()

    private lazy var registerButton: UIButton = {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .label
        configuration.baseForegroundColor = ThemeColor.primary
        configuration.cornerStyle = .medium
        let button = UIButton(configuration: configuration)
        button.addAction(UIAction { [weak self] _ in self?.onRegister?() }, for: .touchUpInside)
        return button
    }()

    private lazy var actionStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [loginButton, registerButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = Layout.actionSpacing
        return stackView
    }()

    private lazy var contentStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconImageView,
            titleLabel,
            messageLabel,
            actionStackView
        ])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = Layout.textSpacing
        stackView.setCustomSpacing(Layout.actionTopSpacing, after: messageLabel)
        return stackView
    }()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Life Cycle

    override func prepareForReuse() {
        super.prepareForReuse()
        onLogin = nil
        onRegister = nil
    }

    // MARK: - Configuration

    func configure(
        with item: MainMemberSettingGuestPromptItem,
        onLogin: @escaping () -> Void,
        onRegister: @escaping () -> Void
    ) {
        iconImageView.image = UIImage(systemName: item.systemImageName)
        titleLabel.text = item.title
        messageLabel.text = item.message
        loginButton.configuration?.attributedTitle = Self.buttonTitle(item.loginTitle)
        registerButton.configuration?.attributedTitle = Self.buttonTitle(item.registerTitle)
        self.onLogin = onLogin
        self.onRegister = onRegister
    }

    // MARK: - Layout

    private func setupView() {
        contentView.backgroundColor = .secondarySystemGroupedBackground
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.layer.cornerCurve = .continuous
        contentView.clipsToBounds = true
        contentView.addSubview(contentStackView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        actionStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.contentInset),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Layout.contentInset),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.contentInset),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -Layout.contentInset),
            iconImageView.heightAnchor.constraint(equalToConstant: Layout.iconSize),
            actionStackView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor),
            actionStackView.heightAnchor.constraint(equalToConstant: Layout.actionHeight)
        ])
    }

    // MARK: - Helpers

    private static func buttonTitle(_ title: String) -> AttributedString {
        var attributedTitle = AttributedString(title)
        attributedTitle.font = UIFont.preferredFont(forTextStyle: .headline)
        return attributedTitle
    }
}
