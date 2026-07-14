//
//  LoginViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import Observation

// MARK: - State

enum LoginState: Equatable {
    case idle
    case loading
    case success(sessionId: String)
    case guestSuccess(guestSessionId: String)
    case failed(ErrorMessage, recoveryAction: LoginFailureRecoveryAction)
}

// MARK: - LoginFailureRecoveryAction

nonisolated enum LoginFailureRecoveryAction: Equatable {
    case editCredentials
    case retry
}

// MARK: - LoginViewModel

@MainActor
@Observable
final class LoginViewModel {

    // MARK: - Properties

    var username = ""
    var password = ""
    private(set) var state: LoginState = .idle

    private let authService: TMDBAuthServicing
    private var authenticationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(authService: TMDBAuthServicing = TMDBAuthService()) {
        self.authService = authService
    }

    // MARK: - Public Methods

    func login() {
        guard !username.isEmpty, !password.isEmpty else { return }
        guard !state.isLoading else { return }

        authenticationTask?.cancel()
        authenticationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await performLogin()
        }
    }

    func continueAsGuest() {
        guard !state.isLoading else { return }

        authenticationTask?.cancel()
        authenticationTask = Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await performGuestLogin()
        }
    }

    func reportFailure(_ message: ErrorMessage) {
        state = .failed(message, recoveryAction: .retry)
    }

    // MARK: - Private Methods

    private func performLogin() async {
        state = .loading

        do {
            let sessionId = try await authService.login(username: username, password: password)
            guard !Task.isCancelled else { return }
            state = .success(sessionId: sessionId)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(
                error.errorMessage,
                recoveryAction: makeLoginFailureRecoveryAction(for: error)
            )
        }
    }

    private func performGuestLogin() async {
        state = .loading

        do {
            let guestSessionId = try await authService.createGuestSession()
            guard !Task.isCancelled else { return }
            state = .guestSuccess(guestSessionId: guestSessionId)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage, recoveryAction: .retry)
        }
    }

    private func makeLoginFailureRecoveryAction(for error: Error) -> LoginFailureRecoveryAction {
        if let networkError = error as? NetworkError,
           networkError.isAuthenticationFailure {
            return .editCredentials
        }

        if let urlError = error as? URLError,
           urlError.code == .userAuthenticationRequired {
            return .editCredentials
        }

        return .retry
    }
}

// MARK: - LoginState Helpers

private extension LoginState {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
}

private extension NetworkError {
    var isAuthenticationFailure: Bool {
        switch self {
        case .httpError(let statusCode), .apiError(let statusCode, _, _):
            return statusCode == 401

        case .invalidURL, .invalidResponse, .requestFailed, .encodingFailed, .decodingFailed:
            return false
        }
    }
}
