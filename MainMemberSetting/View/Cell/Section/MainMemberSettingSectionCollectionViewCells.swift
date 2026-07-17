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
            Task { @MainActor in
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
