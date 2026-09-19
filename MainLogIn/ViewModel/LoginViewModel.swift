//
//  LoginViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation

// MARK: - State

enum LoginState: Equatable {
    case idle
    case loading
    case success(sessionID: String)
    case guestSuccess(guestSessionID: String)
    case failed(ErrorMessage, recoveryAction: LoginFailureRecoveryAction)
}

// MARK: - LoginFailureRecoveryAction

nonisolated enum LoginFailureRecoveryAction: Equatable {
    case editCredentials
    case retry
}

// MARK: - LoginViewModel

@MainActor
final class LoginViewModel {

    // MARK: - Properties

    var username = ""
    var password = ""
    private(set) var state: LoginState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (LoginState) -> Void)?
    private let authentication: AuthenticationProviding
    private let localization: AppInterfaceLocalization
    private var authenticationTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        authentication: AuthenticationProviding,
        localization: AppInterfaceLocalization
    ) {
        self.authentication = authentication
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (LoginState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func login() {
        guard !state.isLoading else { return }

        switch validateCredentials() {
        case .valid:
            break

        case .invalid(let message):
            state = .failed(message, recoveryAction: .editCredentials)
            return
        }

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
            let sessionID = try await authentication.createUserSession(username: username, password: password)
            guard !Task.isCancelled else { return }
            state = .success(sessionID: sessionID)
        } catch {
            guard !Task.isCancelled else { return }
            let recoveryAction = makeLoginFailureRecoveryAction(for: error)
            state = .failed(
                makeLoginFailureMessage(for: error, recoveryAction: recoveryAction),
                recoveryAction: recoveryAction
            )
        }
    }

    private func performGuestLogin() async {
        state = .loading

        do {
            let guestSessionID = try await authentication.createGuestSession()
            guard !Task.isCancelled else { return }
            state = .guestSuccess(guestSessionID: guestSessionID)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization), recoveryAction: .retry)
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

    private func makeLoginFailureMessage(
        for error: Error,
        recoveryAction: LoginFailureRecoveryAction
    ) -> ErrorMessage {
        switch recoveryAction {
        case .editCredentials:
            return ErrorMessage(
                title: localization.string(
                    "login.error.invalid_credentials.title",
                    defaultValue: "Incorrect Username or Password"
                ),
                message: localization.string(
                    "login.error.invalid_credentials.message",
                    defaultValue: "Check your TMDB username and password, then try again."
                ),
                systemImageName: "person.crop.circle.badge.exclamationmark",
                actionTitle: localization.string(
                    "login.action.edit_credentials",
                    defaultValue: "Edit Credentials"
                )
            )

        case .retry:
            return error.errorMessage(localization: localization)
        }
    }

    private func validateCredentials() -> LoginCredentialValidationResult {
        let isUsernameEmpty = username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isPasswordEmpty = password.isEmpty

        switch (isUsernameEmpty, isPasswordEmpty) {
        case (true, true):
            return .invalid(
                ErrorMessage(
                    title: localization.string(
                        "login.validation.missing_credentials.title",
                        defaultValue: "Enter Username and Password"
                    ),
                    message: localization.string(
                        "login.validation.missing_credentials.message",
                        defaultValue: "Enter your TMDB username and password before signing in."
                    ),
                    systemImageName: "person.text.rectangle",
                    actionTitle: localization.string(
                        "login.action.edit_credentials",
                        defaultValue: "Edit Credentials"
                    )
                )
            )

        case (true, false):
            return .invalid(
                ErrorMessage(
                    title: localization.string(
                        "login.validation.missing_username.title",
                        defaultValue: "Enter Username"
                    ),
                    message: localization.string(
                        "login.validation.missing_username.message",
                        defaultValue: "Enter your TMDB username before signing in."
                    ),
                    systemImageName: "person.crop.circle",
                    actionTitle: localization.string(
                        "login.action.edit_credentials",
                        defaultValue: "Edit Credentials"
                    )
                )
            )

        case (false, true):
            return .invalid(
                ErrorMessage(
                    title: localization.string(
                        "login.validation.missing_password.title",
                        defaultValue: "Enter Password"
                    ),
                    message: localization.string(
                        "login.validation.missing_password.message",
                        defaultValue: "Enter your TMDB password before signing in."
                    ),
                    systemImageName: "lock",
                    actionTitle: localization.string(
                        "login.action.edit_credentials",
                        defaultValue: "Edit Credentials"
                    )
                )
            )

        case (false, false):
            return .valid
        }
    }
}

// MARK: - LoginCredentialValidationResult

private enum LoginCredentialValidationResult: Equatable {
    case valid
    case invalid(ErrorMessage)
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
