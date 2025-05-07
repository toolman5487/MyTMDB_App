//
//  TVDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/7.
//

import Foundation
import Combine

class TVDetailViewModel {
    @Published private(set) var tvSeries: TVDetailModel?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: TVDetailServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let tvId: Int

    init(tvId: Int, service: TVDetailServiceProtocol = TVDetailService()) {
        self.tvId = tvId
        self.service = service
        print("VM got id:", tvId)
        fetchDetail()
    }

    func fetchDetail() {
        isLoading = true
        service.fetchTVDetail(id: tvId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(error) = completion {
                    print(error)
                    self?.errorMessage = error.localizedDescription
                }
            } receiveValue: { [weak self] model in
                print("got model:", model.name)
                self?.tvSeries = model
            }
            .store(in: &cancellables)
    }
}
