//
//  MainTabBarAvatarImageProvider.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import UIKit

// MARK: - MainTabBarAvatarProviding

@MainActor
protocol MainTabBarAvatarProviding: AnyObject {
    func fetchAvatarImage(sessionId: String, displayScale: CGFloat) async -> UIImage?
}

// MARK: - MainTabBarAvatarImageProvider

@MainActor
final class MainTabBarAvatarImageProvider: MainTabBarAvatarProviding {

    private enum Layout {
        static let imageSize = CGSize(width: 28, height: 28)
    }

    // MARK: - Properties

    private let avatarProvider: AccountAvatarProviding

    // MARK: - Initialization

    init(avatarProvider: AccountAvatarProviding) {
        self.avatarProvider = avatarProvider
    }

    // MARK: - MainTabBarAvatarProviding

    func fetchAvatarImage(sessionId: String, displayScale: CGFloat) async -> UIImage? {
        do {
            guard let data = try await avatarProvider.avatarImageData(sessionID: sessionId),
                  let image = UIImage(data: data) else {
                return nil
            }

            return makeTabBarAvatarImage(from: image, displayScale: displayScale)
        } catch {
            AppLogger.authentication.error(
                "Failed to fetch tab bar avatar: \(error.errorMessage.message, privacy: .public)"
            )
            return nil
        }
    }

    // MARK: - Helpers

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
