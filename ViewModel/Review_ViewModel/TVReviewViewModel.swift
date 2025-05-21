//
//  TVReviewViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/19.
//

import Foundation
import Combine

final class TVReviewViewModel {

    private let tvId: Int
    private let service: TVReviewServiceProtocol

    @Published private(set) var reviews: [Review] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init(tvId: Int,
         service: TVReviewServiceProtocol = TVReviewService()) {
        self.tvId = tvId
        self.service = service
    }

    func fetchReviews() {
        isLoading = true
        errorMessage = nil
        service.fetchAllReviews(tvId: tvId)
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
                self?.reviews = results
            }
            .store(in: &cancellables)
    }
}
