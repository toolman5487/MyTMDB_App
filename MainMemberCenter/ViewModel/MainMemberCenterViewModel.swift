//
//  MainMemberCenterViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation
import Observation

// MARK: - MainMemberCenterViewModel

@MainActor
@Observable
final class MainMemberCenterViewModel {

    // MARK: - Properties

    private(set) var state: MainMemberCenterViewState = .idle

    private let session: AuthSession
    private let service: MainMemberCenterServicing

    // MARK: - Initialization

    init(
        session: AuthSession,
        service: MainMemberCenterServicing = MainMemberCenterService()
    ) {
        self.session = session
        self.service = service
    }

    // MARK: - Public Methods

    func loadContent() async {
        switch session {
        case .user(let sessionId):
            await loadUserContent(sessionId: sessionId)

        case .guest, .loggedOut:
            state = .guest(MainMemberCenterPresentationBuilder.makeGuestContent())
        }
    }

    // MARK: - Private Methods

    private func loadUserContent(sessionId: String) async {
        state = .loading

        do {
            let snapshot = try await service.fetchContent(sessionId: sessionId)
            guard !Task.isCancelled else { return }
            let content = MainMemberCenterPresentationBuilder.makeContent(from: snapshot)
            state = .loaded(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }
}
