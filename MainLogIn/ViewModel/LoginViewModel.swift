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
    case failed(message: String)
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

    // MARK: - Initialization

    init(authService: TMDBAuthServicing = TMDBAuthService()) {
        self.authService = authService
    }

    // MARK: - Public Methods

    func login() async {
        guard !username.isEmpty, !password.isEmpty else { return }

        state = .loading

        do {
            let sessionId = try await authService.login(username: username, password: password)
            state = .success(sessionId: sessionId)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func continueAsGuest() async {
        state = .loading

        do {
            let guestSessionId = try await authService.createGuestSession()
            state = .guestSuccess(guestSessionId: guestSessionId)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}
