//
//  MovieSearchViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import Combine

final class MovieSearchViewModel {
    
    @Published private(set) var movies: [Movie] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let service: MovieSearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(service: MovieSearchServiceProtocol = MovieSearchService()) {
        self.service = service
    }

    func searchMovies(query: String) {
        guard !query.isEmpty else {
            movies = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        service.searchMovies(query: query, page: 1)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] results in
                self?.movies = results
            }
            .store(in: &cancellables)
    }
}
