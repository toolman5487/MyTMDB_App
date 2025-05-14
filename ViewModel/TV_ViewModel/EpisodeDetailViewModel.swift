//
//  EpisodeDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/13.
//

import Foundation
import Combine

class EpisodeDetailViewModel {
    @Published private(set) var episode: EpisodeModel?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: TVDetailServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let tvId: Int
    private let seasonNumber: Int
    private let episodeNumber: Int

    init(tvId: Int,
         seasonNumber: Int,
         episodeNumber: Int,
         service: TVDetailServiceProtocol = TVDetailService()) {
        self.tvId = tvId
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.service = service
    }

    func fetchEpisodeDetail() {
        isLoading = true
        service.fetchEpisodeDetail(tvId: tvId, seasonNumber: seasonNumber,episodeNumber: episodeNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] episode in
                self?.episode = episode
            }
            .store(in: &cancellables)
    }
}
