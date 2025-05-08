//
//  PersonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/8.
//

import Foundation
import Combine

class PersonDetailViewModel {
    @Published private(set) var detail: PersonDetailModel?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: PersonServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    private let personId: Int

    init(personId: Int, service: PersonServiceProtocol = PersonService()) {
        self.personId = personId
        self.service = service
        fetchPersonDetail()
    }

    func fetchPersonDetail() {
        isLoading = true
        service.fetchPersonDetail(id: personId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case let .failure(err) = completion {
                    self?.errorMessage = err.localizedDescription
                }
            } receiveValue: { [weak self] model in
                self?.detail = model
            }
            .store(in: &cancellables)
    }
}
