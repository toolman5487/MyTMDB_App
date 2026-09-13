//
//  LoadAccountMediaStateUseCase.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - LoadAccountMediaStateUseCase

nonisolated protocol LoadAccountMediaStateUseCase: Sendable {
    func callAsFunction(kind: MediaKind, mediaID: Int) async throws -> AccountMediaState
}

// MARK: - DefaultLoadAccountMediaStateUseCase

nonisolated struct DefaultLoadAccountMediaStateUseCase: LoadAccountMediaStateUseCase {
    private let sessionRepository: AccountSessionProviding
    private let mediaRepository: AccountMediaStateProviding

    init(
        sessionRepository: AccountSessionProviding,
        mediaRepository: AccountMediaStateProviding
    ) {
        self.sessionRepository = sessionRepository
        self.mediaRepository = mediaRepository
    }

    func callAsFunction(kind: MediaKind, mediaID: Int) async throws -> AccountMediaState {
        guard mediaID > 0 else { throw AccountMediaError.invalidIdentifier }
        guard let session = try await sessionRepository.currentUserSession() else {
            throw AccountMediaError.requiresUserLogin
        }

        return try await mediaRepository.mediaState(
            kind: kind,
            mediaID: mediaID,
            sessionID: session.sessionID
        )
    }
}
