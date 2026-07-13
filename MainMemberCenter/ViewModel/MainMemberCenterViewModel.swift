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
    private(set) var headerContent: MainMemberCenterProfileHeaderContent?
    private(set) var displaySections: [MainMemberCenterDisplaySection] = []

    private let session: AuthSession
    private let contentRepository: MainMemberCenterContentProviding
    private var cachedHeaderContent: MainMemberCenterProfileHeaderContent?
    private var accountContext: MainMemberCenterAccountContext?

    // MARK: - Initialization

    init(
        session: AuthSession,
        contentRepository: MainMemberCenterContentProviding = MainMemberCenterContentRepository()
    ) {
        self.session = session
        self.contentRepository = contentRepository
        self.cachedHeaderContent = contentRepository.cachedHeaderContent(for: session)
        self.headerContent = cachedHeaderContent
    }

    // MARK: - Public Methods

    func loadContent() async {
        switch session {
        case .user(let sessionId):
            await loadUserContent(sessionId: sessionId)

        case .guest, .loggedOut:
            apply(state: .guest(MainMemberCenterPresentationBuilder.makeGuestContent()))
        }
    }

    func refreshContentFromTabSelection() async {
        guard isUserSession else { return }
        guard state != .loading else { return }
        await loadContent()
    }

    var profileAction: MainMemberCenterProfileAction {
        switch session {
        case .user:
            return .settings

        case .guest, .loggedOut:
            return .login
        }
    }

    func listRoute(for destination: MainMemberCenterDestination) -> MainMemberCenterListRoute? {
        guard let accountContext else { return nil }
        return MainMemberCenterListRoute(
            destination: destination,
            accountId: accountContext.accountId,
            sessionId: accountContext.sessionId
        )
    }

    // MARK: - Private Methods

    private func loadUserContent(sessionId: String) async {
        apply(state: .loading)

        do {
            let snapshot = try await contentRepository.fetchContent(sessionId: sessionId)
            guard !Task.isCancelled else { return }
            let content = MainMemberCenterPresentationBuilder.makeContent(from: snapshot)
            cachedHeaderContent = content.profile.headerContent
            apply(state: .loaded(content))
        } catch {
            guard !Task.isCancelled else { return }
            apply(state: .failed(error.errorMessage))
        }
    }

    private var isUserSession: Bool {
        if case .user = session {
            return true
        }

        return false
    }

    private func apply(state newState: MainMemberCenterViewState) {
        let presentation = makePresentation(for: newState)

        headerContent = presentation.headerContent
        displaySections = presentation.displaySections
        accountContext = presentation.accountContext
        state = newState
    }

    private func makePresentation(
        for state: MainMemberCenterViewState
    ) -> (
        headerContent: MainMemberCenterProfileHeaderContent?,
        displaySections: [MainMemberCenterDisplaySection],
        accountContext: MainMemberCenterAccountContext?
    ) {
        switch state {
        case .idle:
            return (nil, [], nil)

        case .loading:
            return (cachedHeaderContent, [], nil)

        case .guest(let content):
            return (
                content.profile.headerContent,
                [.guestLogin(content.loginPrompt)],
                nil
            )

        case .loaded(let content):
            let accountContext = makeAccountContext(profile: content.profile)
            return (
                content.profile.headerContent,
                content.contentSections.map(MainMemberCenterDisplaySection.content),
                accountContext
            )

        case .failed:
            return (nil, [], nil)
        }
    }

    private func makeAccountContext(profile: MainMemberCenterProfile) -> MainMemberCenterAccountContext? {
        guard case .user(let sessionId) = session else { return nil }

        return MainMemberCenterAccountContext(
            accountId: profile.id,
            sessionId: sessionId
        )
    }
}
