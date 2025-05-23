//
//  SeasonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/12.
//

import Foundation
import Combine

class SeasonDetailViewModel {
    @Published private(set) var episodes: [EpisodeModel] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: TVDetailServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let tvId: Int
    private let seasonNumber: Int

    init(tvId: Int, seasonNumber: Int, service: TVDetailServiceProtocol = TVDetailService()) {
        self.tvId = tvId
        self.seasonNumber = seasonNumber
        self.service = service
    }

    func fetchEpisodes() {
        isLoading = true
        service.fetchSeasonDetail(tvId: tvId, seasonNumber: seasonNumber)
            .map(\.episodes)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] episodes in
                self?.episodes = episodes
            }
            .store(in: &cancellables)
    }
}
