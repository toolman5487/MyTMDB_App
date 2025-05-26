//
//  TVListViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/23.
//

import Foundation
import Combine

final class TVListViewModel {
    
    @Published var airingToday: [TVListShow] = []
    @Published var onTheAir: [TVListShow] = []
    @Published var popular: [TVListShow] = []
    @Published var topRated: [TVListShow] = []
    @Published var errorMessage: String?
    
    private let airingTodayService: AiringTodayServiceProtocol
    private let onTheAirService: OnTheAirServiceProtocol
    private let popularService: PopularTVServiceProtocol
    private let topRatedService: TopRatedTVServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    enum TVCategory {
        case airingToday, onTheAir, popular, topRated
    }

    init(
        airingTodayService: AiringTodayServiceProtocol,
        onTheAirService: OnTheAirServiceProtocol,
        popularService: PopularTVServiceProtocol,
        topRatedService: TopRatedTVServiceProtocol
    ) {
        self.airingTodayService = airingTodayService
        self.onTheAirService = onTheAirService
        self.popularService = popularService
        self.topRatedService = topRatedService
        fetchAllTVLists()
    }

  func fetchAllTVLists() {
        Publishers.Zip4(
            airingTodayService.fetchAiringToday(),
            onTheAirService.fetchOnTheAir(),
            popularService.fetchPopularTV(),
            topRatedService.fetchTopRated()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }, receiveValue: { [weak self] airing, onAir, popularTV, topTV in
            let sortedAiring    = airing.sorted { $0.firstAirDate > $1.firstAirDate }
            let sortedOnTheAir  = onAir.sorted { $0.firstAirDate > $1.firstAirDate }
            let sortedPopular   = popularTV.sorted { $0.popularity > $1.popularity }
            let sortedTopRated  = topTV.sorted { $0.voteAverage > $1.voteAverage }

            self?.airingToday = sortedAiring
            self?.onTheAir    = sortedOnTheAir
            self?.popular     = sortedPopular
            self?.topRated    = sortedTopRated
        })
        .store(in: &cancellables)
    }

    func fetch(category: TVCategory) {
        let publisher: AnyPublisher<[TVListShow], Error>
        switch category {
        case .airingToday:
            publisher = airingTodayService.fetchAiringToday()
        case .onTheAir:
            publisher = onTheAirService.fetchOnTheAir()
        case .popular:
            publisher = popularService.fetchPopularTV()
        case .topRated:
            publisher = topRatedService.fetchTopRated()
        }
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] shows in
                switch category {
                case .airingToday:
                    self?.airingToday = shows
                case .onTheAir:
                    self?.onTheAir = shows
                case .popular:
                    self?.popular = shows
                case .topRated:
                    self?.topRated = shows
                }
            })
            .store(in: &cancellables)
    }
}
