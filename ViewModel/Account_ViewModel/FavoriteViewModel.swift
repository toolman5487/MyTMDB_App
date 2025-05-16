//
//  FavoriteViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/15.
//

import Foundation
import Combine

class FavoriteViewModel {
  
    private var favoriteKey: String {
        return "\(mediaType)_\(mediaId)_favorite"
    }

    @Published private(set) var isFavorite: Bool = false
    @Published private(set) var errorMessage: String?

    private let service: FavoriteServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let mediaType: String
    private let mediaId: Int
    private let accountId: Int
    private let sessionId: String

    init(mediaType: String,
         mediaId: Int,
         accountId: Int,
         sessionId: String,
         service: FavoriteServiceProtocol = FavoriteService()) {
        self.mediaType = mediaType
        self.mediaId = mediaId
        self.accountId = accountId
        self.sessionId = sessionId
        self.service = service
        // Load cached favorite state if available
        self.isFavorite = UserDefaults.standard.bool(forKey: favoriteKey)
        fetchFavoriteState()
    }

    func fetchFavoriteState() {
        service.fetchFavoriteState(mediaType: mediaType,
                                   mediaId: mediaId,
                                   sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] state in
                self?.isFavorite = state.favorite
                print("Fetched favorite state for \(self?.mediaType ?? "") id \(self?.mediaId ?? 0): isFavorite = \(state.favorite)")
            }
            .store(in: &cancellables)
    }

    func toggleFavorite() {
        let newValue = !isFavorite
        service.toggleFavorite(mediaType: mediaType,
                               mediaId: mediaId,
                               favorite: newValue,
                               accountId: accountId,
                               sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("toggleFavorite failed:", error)
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] _ in
                self?.isFavorite = newValue
                UserDefaults.standard.set(newValue, forKey: self?.favoriteKey ?? "")
                print("toggleFavorite succeeded for \(self?.mediaType ?? "") id: \(self?.mediaId ?? 0)")
            }
            .store(in: &cancellables)
    }
}
