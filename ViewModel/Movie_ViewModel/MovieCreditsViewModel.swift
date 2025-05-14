//
//  MovieCreditsViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/14.
//

import Combine
import Foundation

class MovieCreditsViewModel {
    @Published private(set) var cast: [CastMember] = []
    @Published private(set) var errorMessage: String?
    private var cancellables = Set<AnyCancellable>()
    private let service: MovieCreditsServiceProtocol
    private let movieId: Int

    init(movieId: Int, service: MovieCreditsServiceProtocol = MovieCreditsService()) {
        self.movieId = movieId
        self.service = service
    }

    func loadCredits() {
        service.fetchMovieCredits(movieId: movieId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.cast = response.cast
            }
            .store(in: &cancellables)
    }
}
