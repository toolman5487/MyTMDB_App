//
//  MainMyAccountViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation
import Observation

// MARK: - State

enum MainMyAccountState: Equatable {
    case idle
    case loading
    case guest
    case loaded(MainMyAccountProfileResponse)
    case failed(message: String)
}

// MARK: - MainMyAccountViewModel

@MainActor
@Observable
final class MainMyAccountViewModel {

    // MARK: - Properties

    private(set) var state: MainMyAccountState = .idle

    private let service: MainMyAccountServicing

    // MARK: - Initialization

    init(service: MainMyAccountServicing = MainMyAccountService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadProfile(for session: AuthSession, force: Bool = false) async {
        if session.isGuest {
            state = .guest
            return
        }

        guard let sessionId = session.sessionId else {
            state = .failed(message: "尚未登入")
            return
        }

        if !force, shouldSkipLoading(for: session) {
            return
        }

        AppLogger.domain.debug("Start loading my account profile")
        state = .loading

        do {
            let profile = try await service.fetchProfile(sessionId: sessionId)
            state = .loaded(profile)
            AppLogger.domain.info(
                "My account profile loaded for user \(profile.username, privacy: .public)"
            )
        } catch {
            let message = error.localizedDescription
            state = .failed(message: message)
            AppLogger.domain.error(
                "Failed to load my account profile: \(message, privacy: .public)"
            )
        }
    }

    // MARK: - Private Methods

    private func shouldSkipLoading(for session: AuthSession) -> Bool {
        switch state {
        case .loaded, .guest, .failed:
            return true

        case .idle, .loading:
            return false
        }
    }
}
