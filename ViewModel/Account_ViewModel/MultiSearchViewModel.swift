//
//  MultiSearchViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Combine

final class MultiSearchViewModel {
    @Published private(set) var results: [MultiSearchResult] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    
    private let service: MultiSearchServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(service: MultiSearchServiceProtocol = MultiSearchService()) {
        self.service = service
    }
    
    func search(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            results = []
            return
        }
        isLoading = true
        errorMessage = nil
        service.search(query: trimmed)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] response in
                self?.results = response.results
            }
            .store(in: &cancellables)
    }
}
