//
//  AllTrendingViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import Combine

final class AllTrendingViewModel {
    
    @Published private(set) var weeklyTrendingItems: [TrendingItem] = []
    @Published private(set) var dailyTrendingItems: [TrendingItem] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading: Bool = false

    private let service: AllTrendingServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: AllTrendingServiceProtocol = AllTrendingService()) {
        self.service = service
    }

    func fetchDailyTrending() {
        isLoading = true
        errorMessage = nil
        service.fetchTrendingAll(timeWindow: "day")
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] items in
                self?.dailyTrendingItems = items
            }
            .store(in: &cancellables)
    }

    func fetchWeeklyTrending() {
        isLoading = true
        errorMessage = nil
        service.fetchTrendingAll(timeWindow: "week")
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] items in
                self?.weeklyTrendingItems = items
            }
            .store(in: &cancellables)
    }
}
