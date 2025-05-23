//
//  TVSearchViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/22.
//

import Foundation
import Combine

final class TVSearchViewModel {
    
    @Published var results: [TVShow] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    private let service: TVSearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(service: TVSearchServiceProtocol = TVSearchService()) {
        self.service = service
    }

    func search(query: String, page: Int = 1) {
        guard !query.isEmpty else {
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        service.searchTV(query: query, page: page)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] shows in
                self?.results = shows
            }
            .store(in: &cancellables)
    }
}
