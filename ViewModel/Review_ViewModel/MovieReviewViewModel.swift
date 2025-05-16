//
//  MovieReviewViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/16.
//

import Foundation
import Combine

final class MovieReviewViewModel {
    
    private let movieId: Int
    private let service: MovieReviewServiceProtocol
    
    @Published private(set) var reviews: [Review] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(movieId: Int,
         service: MovieReviewServiceProtocol = MovieReviewService()) {
        self.movieId = movieId
        self.service = service
    }
    
    func fetchReviews() {
        print("MovieReviewViewModel: fetchReviews called for movieId:", movieId)
        isLoading = true
        errorMessage = nil
        service.fetchAllReviews(movieId: movieId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                print("MovieReviewViewModel: fetchReviews completion:", completion)
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    print("MovieReviewViewModel: fetchReviews error:", error)
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] results in
                print("MovieReviewViewModel: received reviews count:", results.count)
                self?.reviews = results
            }
            .store(in: &cancellables)
    }
}
