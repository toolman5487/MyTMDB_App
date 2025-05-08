//
//  MovieDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation
import UIKit
import Combine

final class MovieDetailViewModel{
    @Published private(set) var movie: MovieDetailModel?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let service: MovieServiceProtocol
    private let movieId: Int
    private var cancellables = Set<AnyCancellable>()
    
    init(movieId: Int, service: MovieServiceProtocol = MovieDetailService()) {
        self.movieId = movieId
        self.service = service
    }
    
    func fetchMovieDetail() {
            isLoading = true
            errorMessage = nil
            service.fetchMovieDetail(id: movieId)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let err) = completion {
                        self?.errorMessage = err.localizedDescription
                    }
                } receiveValue: { [weak self] detail in
                    self?.movie = detail
                }
                .store(in: &cancellables)
        }
}
