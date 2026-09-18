//
//  AuthenticationRepository.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AuthenticationRepository

nonisolated final class AuthenticationRepository: AuthenticationProviding {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing) {
        self.network = network
    }

    // MARK: - AuthenticationProviding

    func createUserSession(username: String, password: String) async throws -> String {
        let requestToken = try await requestToken()
        try await validate(requestToken: requestToken, username: username, password: password)

        let dto: UserSessionDTO = try await network.post(
            path: APIConfig.Authentication.sessionNew,
            body: UserSessionRequestDTO(requestToken: requestToken)
        )
        guard dto.success else {
            throw URLError(.userAuthenticationRequired)
        }

        return dto.sessionID
    }

    func createGuestSession() async throws -> String {
        let dto: GuestSessionDTO = try await network.post(
            path: APIConfig.Authentication.guestSessionNew,
            body: nil
        )
        guard dto.success else {
            throw URLError(.userAuthenticationRequired)
        }

        return dto.guestSessionID
    }

    func deleteUserSession(sessionID: String) async throws {
        let dto: SessionDeletionResponseDTO = try await network.delete(
            path: APIConfig.Authentication.session,
            queryItems: [],
            body: SessionDeletionRequestDTO(sessionID: sessionID)
        )
        guard dto.success else {
            throw URLError(.userAuthenticationRequired)
        }
    }

    // MARK: - Helpers

    private func requestToken() async throws -> String {
        let dto: RequestTokenDTO = try await network.get(
            path: APIConfig.Authentication.tokenNew
        )
        guard dto.success else {
            throw URLError(.userAuthenticationRequired)
        }

        return dto.requestToken
    }

    private func validate(requestToken: String, username: String, password: String) async throws {
        let dto: TokenValidationDTO = try await network.post(
            path: APIConfig.Authentication.tokenValidateWithLogin,
            body: TokenValidationRequestDTO(
                username: username,
                password: password,
                requestToken: requestToken
            )
        )
        guard dto.success else {
            throw URLError(.userAuthenticationRequired)
        }
    }
}
