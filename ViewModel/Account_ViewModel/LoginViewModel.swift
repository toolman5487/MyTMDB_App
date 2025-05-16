//
//  LoginViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import Combine

final class LoginViewModel {
    
    @Published var username: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var sessionId: String?
    @Published private(set) var errorMessage: String?
    
    let loginTap = PassthroughSubject<Void, Never>()
    private let authService: TMDBAuthService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: TMDBAuthService = TMDBAuthService()) {
        self.authService = authService
        bind()
    }
    
    private func bind() {
        loginTap
            .filter { [unowned self] in
                return !username.isEmpty && !password.isEmpty
            }
            .handleEvents(receiveOutput: { [unowned self] _ in
                isLoading = true
                errorMessage = nil
            })
            .flatMap { [unowned self] in
                authService
                    .loginPublisher(username: username, password: password)
                    .catch { [unowned self] error -> Empty<String, Never> in
                        self.errorMessage = error.localizedDescription
                        return .init()
                    }
            }
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] sid in
                isLoading = false
                sessionId = sid
            }
            .store(in: &cancellables)
    }
}
