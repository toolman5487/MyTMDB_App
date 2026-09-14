//
//  AccountAvatarRepository.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AccountAvatarRepository

nonisolated final class AccountAvatarRepository: AccountAvatarProviding {

    // MARK: - Properties

    private let profileProvider: AccountProfileProviding
    private let userProfileStore: UserProfileStoring
    private let urlSession: URLSession

    // MARK: - Initialization

    init(
        profileProvider: AccountProfileProviding,
        userProfileStore: UserProfileStoring,
        urlSession: URLSession
    ) {
        self.profileProvider = profileProvider
        self.userProfileStore = userProfileStore
        self.urlSession = urlSession
    }

    // MARK: - AccountAvatarProviding

    func avatarImageData(sessionID: String) async throws -> Data? {
        if let cachedData = userProfileStore.load()?.avatarImageData {
            return cachedData
        }

        let profile = try await profileProvider.profile(sessionID: sessionID)
        guard let avatarURL = profile.avatarURL else { return nil }

        let (data, response) = try await urlSession.data(from: avatarURL)
        guard Self.isImageResponse(response), !data.isEmpty else { return nil }

        userProfileStore.saveAvatarImageData(data)
        return data
    }

    // MARK: - Helpers

    private static func isImageResponse(_ response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else { return false }

        let isSuccess = (200..<300).contains(httpResponse.statusCode)
        let isImage = httpResponse.mimeType?.hasPrefix("image/") ?? false
        return isSuccess && isImage
    }
}
