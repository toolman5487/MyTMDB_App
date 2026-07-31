//
//  MainTabBarAvatarService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/13.
//

import UIKit

// MARK: - MainTabBarAvatarProviding

@MainActor
protocol MainTabBarAvatarProviding: AnyObject {
    func fetchAvatarImage(sessionId: String, displayScale: CGFloat) async -> UIImage?
}

// MARK: - MainTabBarAvatarService

@MainActor
final class MainTabBarAvatarService: MainTabBarAvatarProviding {

    private enum Layout {
        static let imageSize = CGSize(width: 28, height: 28)
    }

    // MARK: - Properties

    private let accountService: AccountServiceProtocol
    private let userProfileStore: UserProfileStoring
    private let urlSession: URLSession

    // MARK: - Initialization

    init(
        accountService: AccountServiceProtocol = AccountService(),
        userProfileStore: UserProfileStoring = UserProfileStore(),
        urlSession: URLSession = .shared
    ) {
        self.accountService = accountService
        self.userProfileStore = userProfileStore
        self.urlSession = urlSession
    }

    // MARK: - MainTabBarAvatarProviding

    func fetchAvatarImage(sessionId: String, displayScale: CGFloat) async -> UIImage? {
        if let cachedAvatarImage = loadCachedAvatarImage() {
            return makeTabBarAvatarImage(from: cachedAvatarImage, displayScale: displayScale)
        }

        do {
            let account = try await accountService.fetchAccount(sessionId: sessionId)
            let profile = StoredUserProfile(account: account)
            userProfileStore.save(profile)

            guard let avatarURL = profile.avatarURL else { return nil }

            let (data, _) = try await urlSession.data(from: avatarURL)
            guard let image = UIImage(data: data) else { return nil }

            userProfileStore.saveAvatarImageData(data)
            return makeTabBarAvatarImage(from: image, displayScale: displayScale)
        } catch {
            AppLogger.authentication.error(
                "Failed to fetch tab bar avatar: \(error.errorMessage.message, privacy: .public)"
            )
            return nil
        }
    }

    // MARK: - Private Methods

    private func loadCachedAvatarImage() -> UIImage? {
        guard let data = userProfileStore.load()?.avatarImageData,
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    private func makeTabBarAvatarImage(from image: UIImage, displayScale: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = max(displayScale, 1)
        format.opaque = false

        let renderer = UIGraphicsImageRenderer(size: Layout.imageSize, format: format)
        let renderedImage = renderer.image { _ in
            let bounds = CGRect(origin: .zero, size: Layout.imageSize)
            UIBezierPath(ovalIn: bounds).addClip()
            image.draw(in: aspectFillRect(for: image.size, in: bounds))
        }

        return renderedImage.withRenderingMode(.alwaysOriginal)
    }

    private func aspectFillRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        guard imageSize.width > 0, imageSize.height > 0 else {
            return bounds
        }

        let scale = max(
            bounds.width / imageSize.width,
            bounds.height / imageSize.height
        )
        let scaledSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        return CGRect(
            x: bounds.midX - scaledSize.width / 2,
            y: bounds.midY - scaledSize.height / 2,
            width: scaledSize.width,
            height: scaledSize.height
        )
    }
}
