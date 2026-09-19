//
//  MemberCenterViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation

// MARK: - MemberCenterViewModel

@MainActor
final class MemberCenterViewModel {

    // MARK: - Properties

    private(set) var state: MemberCenterViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }
    private(set) var headerContent: MemberCenterProfileHeaderContent?
    private(set) var displaySections: [MemberCenterDisplaySection] = []

    private var onStateChange: (@MainActor (MemberCenterViewState) -> Void)?
    private let session: AuthSession
    private let loadOverview: LoadMemberCenterOverviewUseCase
    private let localization: AppInterfaceLocalization
    private var cachedHeaderContent: MemberCenterProfileHeaderContent?
    private var accountContext: MemberCenterAccountContext?
    private var lastSettledState: MemberCenterViewState = .idle

    // MARK: - Initialization

    init(
        session: AuthSession,
        loadOverview: LoadMemberCenterOverviewUseCase,
        contentRepository: AccountContentProviding,
        localization: AppInterfaceLocalization
    ) {
        self.session = session
        self.loadOverview = loadOverview
        self.localization = localization

        if case .user = session {
            self.cachedHeaderContent = contentRepository
                .cachedProfile()
                .map { MemberCenterProfileHeaderContent(profile: $0, localization: localization) }
        }
        self.headerContent = cachedHeaderContent
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (MemberCenterViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent() async {
        switch session {
        case .user(let sessionID):
            await loadUserContent(sessionID: sessionID)

        case .guest, .loggedOut:
            apply(state: .guest(MemberCenterPresentationBuilder.makeGuestContent(
                localization: localization
            )))
        }
    }

    func refreshContentFromTabSelection() async {
        guard canRefreshContentFromTabSelection else { return }
        await loadInitialContent()
    }

    var canRefreshContentFromTabSelection: Bool {
        isUserSession && !state.isLoading
    }

    var profileAction: MemberCenterProfileAction {
        switch session {
        case .user:
            return .settings

        case .guest, .loggedOut:
            return .login
        }
    }

    func listRoute(for destination: MemberCenterDestination) -> MemberCenterListRoute? {
        guard let accountContext else { return nil }
        return MemberCenterListRoute(
            destination: destination,
            accountID: accountContext.accountID,
            sessionID: accountContext.sessionID
        )
    }

    // MARK: - Private Methods

    private func loadUserContent(sessionID: String) async {
        let cancellationFallbackState = lastSettledState
        apply(state: .loading)

        do {
            let overview = try await loadOverview(sessionID: sessionID)
            guard !Task.isCancelled else {
                apply(state: cancellationFallbackState)
                return
            }

            let content = MemberCenterPresentationBuilder.makeContent(
                from: overview,
                localization: localization
            )
            cachedHeaderContent = MemberCenterProfileHeaderContent(
                profile: content.profile,
                localization: localization
            )
            apply(state: content.contentSections.isEmpty ? .empty(content) : .loaded(content))
        } catch is CancellationError {
            apply(state: cancellationFallbackState)
        } catch {
            guard !Task.isCancelled else {
                apply(state: cancellationFallbackState)
                return
            }

            apply(state: .failed(error.errorMessage(localization: localization)))
        }
    }

    private var isUserSession: Bool {
        if case .user = session {
            return true
        }

        return false
    }

    private func apply(state newState: MemberCenterViewState) {
        let presentation = makePresentation(for: newState)

        headerContent = presentation.headerContent
        displaySections = presentation.displaySections
        accountContext = presentation.accountContext
        state = newState

        guard !newState.isLoading else { return }
        lastSettledState = newState
    }

    private func makePresentation(
        for state: MemberCenterViewState
    ) -> (
        headerContent: MemberCenterProfileHeaderContent?,
        displaySections: [MemberCenterDisplaySection],
        accountContext: MemberCenterAccountContext?
    ) {
        switch state {
        case .idle:
            return (nil, [], nil)

        case .loading:
            return (cachedHeaderContent, [], nil)

        case .guest(let content):
            return (
                content.headerContent,
                [.guestLogin(content.loginPrompt)],
                nil
            )

        case .empty(let content):
            return (
                MemberCenterProfileHeaderContent(profile: content.profile, localization: localization),
                [],
                makeAccountContext(profile: content.profile)
            )

        case .loaded(let content):
            return (
                MemberCenterProfileHeaderContent(profile: content.profile, localization: localization),
                content.contentSections.map(MemberCenterDisplaySection.content),
                makeAccountContext(profile: content.profile)
            )

        case .failed:
            return (nil, [], nil)
        }
    }

    private func makeAccountContext(profile: AccountProfile) -> MemberCenterAccountContext? {
        guard case .user(let sessionID) = session else { return nil }

        return MemberCenterAccountContext(
            accountID: profile.id,
            sessionID: sessionID
        )
    }
}

// MARK: - MemberCenterViewState

private extension MemberCenterViewState {

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
