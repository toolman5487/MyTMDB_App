//
//  TMDBAuthService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation

// MARK: - Protocol

protocol TMDBAuthServicing {
    func login(username: String, password: String) async throws -> String
    func createGuestSession() async throws -> String
}

// MARK: - TMDBAuthService

final class TMDBAuthService: TMDBAuthServicing {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing = NetworkService()) {
        self.network = network
    }

    // MARK: - Public Methods

    func login(username: String, password: String) async throws -> String {
        let token = try await requestToken()
        let validatedToken = try await validate(token: token, username: username, password: password)
        return try await createSession(token: validatedToken)
    }

    func createGuestSession() async throws -> String {
        let response: GuestSessionResponse = try await network.post(
            path: APIConfig.Authentication.guestSessionNew,
            body: nil
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return response.guest_session_id
    }

    // MARK: - Private Methods

    private func requestToken() async throws -> String {
        let response: TokenResponse = try await network.get(
            path: APIConfig.Authentication.tokenNew
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return response.request_token
    }

    private func validate(token: String, username: String, password: String) async throws -> String {
        let credentials = ValidateCredentials(
            username: username,
            password: password,
            request_token: token
        )
        let response: ValidateResponse = try await network.post(
            path: APIConfig.Authentication.tokenValidateWithLogin,
            body: credentials
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return token
    }

    private func createSession(token: String) async throws -> String {
        let response: SessionResponse = try await network.post(
            path: APIConfig.Authentication.sessionNew,
            body: SessionRequest(request_token: token)
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return response.session_id
    }
}

// MARK: - Request Models

private struct ValidateCredentials: Encodable {
    let username: String
    let password: String
    let request_token: String
}

private struct SessionRequest: Encodable {
    let request_token: String
}
