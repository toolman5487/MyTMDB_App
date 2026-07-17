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
    private var lastSettledState: MainMemberCenterViewState = .idle

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
        guard canRefreshContentFromTabSelection else { return }
        await loadContent()
    }

    var canRefreshContentFromTabSelection: Bool {
        isUserSession && !state.isLoading
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
        let cancellationFallbackState = lastSettledState
        apply(state: .loading)

        do {
            let snapshot = try await contentRepository.fetchContent(sessionId: sessionId)
            guard !Task.isCancelled else {
                apply(state: cancellationFallbackState)
                return
            }

            let content = MainMemberCenterPresentationBuilder.makeContent(from: snapshot)
            cachedHeaderContent = content.profile.headerContent
            apply(state: content.contentSections.isEmpty ? .empty(content) : .loaded(content))
        } catch is CancellationError {
            apply(state: cancellationFallbackState)
        } catch {
            guard !Task.isCancelled else {
                apply(state: cancellationFallbackState)
                return
            }

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

        guard !newState.isLoading else { return }
        lastSettledState = newState
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

        case .empty(let content):
            let accountContext = makeAccountContext(profile: content.profile)
            return (
                content.profile.headerContent,
                [],
                accountContext
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

// MARK: - MainMemberCenterViewState

private extension MainMemberCenterViewState {

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
