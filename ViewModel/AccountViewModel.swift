//
//  AccountViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Combine

final class AccountViewModel {
    @Published private(set) var account: Account?
    @Published private(set) var errorMessage: String?

    private let service: AccountServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: AccountServiceProtocol = AccountService()) {
        self.service = service
    }

    func loadAccount(sessionId: String) {
        service.fetchAccount(sessionId: sessionId)
          .sink { completion in
            if case .failure(let error) = completion {
              self.errorMessage = error.localizedDescription
            }
          } receiveValue: { account in
            self.account = account
          }
          .store(in: &cancellables)
    }
}
