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
    @Published var didRate: Bool = false
    @Published var rateError: String?
    @Published var accountState: MovieAccountState?

    private let favoriteService: FavoriteServiceProtocol
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
        self.favoriteService = service
        self.isFavorite = UserDefaults.standard.bool(forKey: favoriteKey)
        fetchFavoriteState()
        fetchAccountState()
    }

    func fetchFavoriteState() {
        favoriteService.fetchFavoriteState(mediaType: mediaType,
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
        favoriteService.toggleFavorite(mediaType: mediaType,
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
    
    func rate(_ value: Double) {
        guard value >= 0.5 && value <= 10 else {
            errorMessage = "評分需介於 0.5 到 10 之間"
            return
        }

        favoriteService.rate(mediaType: mediaType, mediaId: mediaId, value: value, sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    self?.didRate = true
                case .failure(let error):
                    self?.rateError = error.localizedDescription
                }
            } receiveValue: { }
            .store(in: &cancellables)
    }
    
    func fetchAccountState() {
       favoriteService.fetchAccountState(movieId: mediaId, sessionId: sessionId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    print("ok")
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] state in
                self?.accountState = state
            }
            .store(in: &cancellables)
    }
}

   
