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
    
    @Published private(set) var favoriteMovies: [FavoriteMovieItem] = []
    @Published private(set) var favoriteTV: [FavoriteTVItem] = []

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

    func loadFavorites(accountId: Int, sessionId: String) {
        service.fetchFavoriteMovies(accountId: accountId, sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] movies in
                self?.favoriteMovies = movies
            }
            .store(in: &cancellables)

        service.fetchFavoriteTV(accountId: accountId, sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] tv in
                print("VM recevie ：", tv.count)
                self?.favoriteTV = tv
            }
            .store(in: &cancellables)
    }
}
