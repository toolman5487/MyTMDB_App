//
//  PersonService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/8.
//

import Foundation
import Combine

protocol PersonServiceProtocol {
    func fetchPersonDetail(id: Int) -> AnyPublisher<PersonDetailModel, Error>
}

final class PersonService: PersonServiceProtocol {
    func fetchPersonDetail(id: Int) -> AnyPublisher<PersonDetailModel, Error> {
        guard let url = URL(string: "\(TMDB.baseURL)/person/\(id)?api_key=\(TMDB.apiKey)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: PersonDetailModel.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
