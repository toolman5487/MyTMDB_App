//
//  MovieListViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/21.
//

import Foundation
import Combine

final class MovieListViewModel {
    
    @Published var nowPlaying: [MovieSummary] = []
    @Published var popular:   [MovieSummary] = []
    @Published var topRated:  [MovieSummary] = []
    @Published var upcoming:  [MovieSummary] = []

    private let nowPlayingService: NowPlayingServiceProtocol
    private let popularService:   PopularMovieServiceProtocol
    private let topRatedService:  TopRatedServiceProtocol
    private let upcomingService:  UpcomingServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(
        nowPlayingService: NowPlayingServiceProtocol,
        popularService:   PopularMovieServiceProtocol,
        topRatedService:  TopRatedServiceProtocol,
        upcomingService:  UpcomingServiceProtocol
    ) {
        self.nowPlayingService = nowPlayingService
        self.popularService   = popularService
        self.topRatedService  = topRatedService
        self.upcomingService  = upcomingService
        fetchAllLists()
    }
    
    enum MovieCategory {
        case nowPlaying, popular, topRated, upcoming
    }

    private func fetchAllLists() {
        Publishers.Zip4(
            nowPlayingService.fetchNowPlaying(),
            popularService.fetchPopular(),
            topRatedService.fetchTopRated(),
            upcomingService.fetchUpcoming()
        )
        .receive(on: DispatchQueue.main)
        .sink(receiveCompletion: { completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                print("Error fetching lists:", error)
            }
        }, receiveValue: { [weak self] now, popular, toprated, upcoming in
            let sortedNowPlaying = now.sorted { $0.releaseDate > $1.releaseDate }
            let sortedPopular    = popular.sorted { $0.popularity > $1.popularity }
            let sortedTopRated   = toprated.sorted { $0.voteAverage > $1.voteAverage }
            let sortedUpcoming   = upcoming.sorted { $0.releaseDate > $1.releaseDate }

            self?.nowPlaying = sortedNowPlaying
            self?.popular    = sortedPopular
            self?.topRated   = sortedTopRated
            self?.upcoming   = sortedUpcoming
        })
        .store(in: &cancellables)
    }

    func fetch(category: MovieCategory) {
        let publisher: AnyPublisher<[MovieSummary], Error>
        switch category {
        case .nowPlaying:
            publisher = nowPlayingService.fetchNowPlaying()
        case .popular:
            publisher = popularService.fetchPopular()
        case .topRated:
            publisher = topRatedService.fetchTopRated()
        case .upcoming:
            publisher = upcomingService.fetchUpcoming()
        }
        publisher
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] movies in
                switch category {
                case .nowPlaying:
                    self?.nowPlaying = movies
                case .popular:
                    self?.popular = movies
                case .topRated:
                    self?.topRated = movies
                case .upcoming:
                    self?.upcoming = movies
                }
            })
            .store(in: &cancellables)
    }
}
