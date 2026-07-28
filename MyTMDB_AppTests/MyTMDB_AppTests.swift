//
//  MyTMDB_AppTests.swift
//  MyTMDB_AppTests
//
//  Created by Willy Hsu on 2025/5/2.
//

import XCTest
@testable import MyTMDB_App

final class MyTMDB_AppTests: XCTestCase {

    func testAppIntentSessionResolverRequiresUserLoginWhenSessionIsGuest() async {
        let resolver = AppIntentSessionResolver(
            sessionStore: StubSessionStore(session: .guest(sessionId: "guest-session")),
            accountService: StubAccountService(account: .makeStub())
        )

        do {
            _ = try await resolver.resolveUserAccountContext()
            XCTFail("Expected requiresUserLogin")
        } catch let error as AppIntentSessionResolutionError {
            XCTAssertEqual(error, .requiresUserLogin)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testAppIntentSessionResolverReturnsUserAccountContext() async throws {
        let resolver = AppIntentSessionResolver(
            sessionStore: StubSessionStore(session: .user(sessionId: "user-session")),
            accountService: StubAccountService(account: .makeStub(id: 42))
        )

        let context = try await resolver.resolveUserAccountContext()

        XCTAssertEqual(context.accountId, 42)
        XCTAssertEqual(context.sessionId, "user-session")
    }

    func testFavoriteActionHandlerSendsFavoriteRequest() async {
        let service = StubMemberCenterService(
            favoriteResponse: MemberCenterFavoriteStatusResponse(
                success: true,
                statusCode: 1,
                statusMessage: "Success."
            )
        )
        let handler = AppIntentFavoriteActionHandler(
            sessionResolver: StubAppIntentSessionResolver(
                context: MemberCenterAccountContext(
                    accountId: 7,
                    sessionId: "session-id"
                )
            ),
            memberCenterService: service
        )

        let outcome = await handler.updateFavorite(
            mediaType: .movie,
            mediaID: 550,
            favorite: true,
            displayTitle: "Fight Club"
        )

        XCTAssertEqual(outcome, .succeeded(message: "已將電影「Fight Club」加入收藏。"))
        XCTAssertEqual(service.favoriteCall?.accountId, 7)
        XCTAssertEqual(service.favoriteCall?.sessionId, "session-id")
        XCTAssertEqual(service.favoriteCall?.request.mediaType.rawValue, MemberCenterAccountMediaType.movie.rawValue)
        XCTAssertEqual(service.favoriteCall?.request.mediaID, 550)
        XCTAssertEqual(service.favoriteCall?.request.favorite, true)
    }

    func testFavoriteActionHandlerReturnsLoginMessageWhenSessionIsMissing() async {
        let handler = AppIntentFavoriteActionHandler(
            sessionResolver: StubAppIntentSessionResolver(error: .requiresUserLogin),
            memberCenterService: StubMemberCenterService()
        )

        let outcome = await handler.updateFavorite(
            mediaType: .tv,
            mediaID: 1399,
            favorite: false,
            displayTitle: "Game of Thrones"
        )

        XCTAssertEqual(outcome, .failed(message: "需要登入 TMDB 帳號後才能更新收藏。"))
    }
}

// MARK: - Test Doubles

private final class StubSessionStore: SessionStoring, @unchecked Sendable {
    private let session: AuthSession

    init(session: AuthSession) {
        self.session = session
    }

    func load() -> AuthSession {
        session
    }

    func save(_ session: AuthSession) {}

    func clear() {}
}

private final class StubAccountService: AccountServiceProtocol, @unchecked Sendable {
    private let account: Account

    init(account: Account) {
        self.account = account
    }

    func fetchAccount(sessionId: String) async throws -> Account {
        account
    }
}

private final class StubAppIntentSessionResolver: AppIntentSessionResolving, @unchecked Sendable {
    private let context: MemberCenterAccountContext?
    private let error: AppIntentSessionResolutionError?

    init(context: MemberCenterAccountContext) {
        self.context = context
        self.error = nil
    }

    init(error: AppIntentSessionResolutionError) {
        self.context = nil
        self.error = error
    }

    func resolveUserAccountContext() async throws -> MemberCenterAccountContext {
        if let error {
            throw error
        }

        guard let context else {
            throw AppIntentSessionResolutionError.invalidAccount
        }

        return context
    }
}

private final class StubMemberCenterService: MemberCenterServicing, @unchecked Sendable {
    struct FavoriteCall {
        let accountId: Int
        let sessionId: String
        let request: MemberCenterFavoriteStatusRequest
    }

    private let favoriteResponse: MemberCenterFavoriteStatusResponse
    private(set) var favoriteCall: FavoriteCall?

    init(
        favoriteResponse: MemberCenterFavoriteStatusResponse = MemberCenterFavoriteStatusResponse(
            success: true,
            statusCode: 1,
            statusMessage: "Success."
        )
    ) {
        self.favoriteResponse = favoriteResponse
    }

    func fetchAccount(sessionId: String) async throws -> Account {
        .makeStub()
    }

    func fetchFavoriteMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterFavoriteMoviePage {
        fatalError("Unused")
    }

    func fetchFavoriteTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterFavoriteTVPage {
        fatalError("Unused")
    }

    func fetchWatchlistMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterWatchlistMoviePage {
        fatalError("Unused")
    }

    func fetchWatchlistTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterWatchlistTVPage {
        fatalError("Unused")
    }

    func fetchRatedMovies(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedMoviePage {
        fatalError("Unused")
    }

    func fetchRatedTV(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedTVPage {
        fatalError("Unused")
    }

    func fetchRatedEpisodes(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterRatedEpisodePage {
        fatalError("Unused")
    }

    func fetchLists(
        accountId: Int,
        sessionId: String,
        page: Int
    ) async throws -> MemberCenterListPage {
        fatalError("Unused")
    }

    func fetchListDetail(listId: Int) async throws -> MemberCenterListDetail {
        fatalError("Unused")
    }

    func updateFavorite(
        accountId: Int,
        sessionId: String,
        request: MemberCenterFavoriteStatusRequest
    ) async throws -> MemberCenterFavoriteStatusResponse {
        favoriteCall = FavoriteCall(
            accountId: accountId,
            sessionId: sessionId,
            request: request
        )
        return favoriteResponse
    }

    func updateWatchlist(
        accountId: Int,
        sessionId: String,
        request: MemberCenterWatchlistStatusRequest
    ) async throws -> MemberCenterWatchlistStatusResponse {
        fatalError("Unused")
    }

    func submitRating(
        sessionId: String,
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountMediaRatingResponse {
        fatalError("Unused")
    }

    func deleteRating(
        sessionId: String,
        target: AccountMediaRatingTarget
    ) async throws -> AccountMediaRatingResponse {
        fatalError("Unused")
    }
}

private extension Account {
    static func makeStub(id: Int = 1) -> Account {
        Account(
            id: id,
            name: "Test User",
            username: "tester",
            include_adult: false,
            iso_639_1: "zh",
            iso_3166_1: "TW",
            avatar: Account.Avatar(
                gravatar: Account.Avatar.Gravatar(hash: ""),
                tmdb: Account.Avatar.TMDBAvatar(avatar_path: nil)
            )
        )
    }
}
