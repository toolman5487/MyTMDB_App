//
//  MultiSearchService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Combine

protocol MultiSearchServiceProtocol {
    func search(query: String) -> AnyPublisher<MultiSearchResponse, Error>
}

final class MultiSearchService: MultiSearchServiceProtocol {
    private let apiKey = TMDB.apiKey
    private let baseURL = "\(TMDB.baseURL)/search/multi"
    private let decoder = JSONDecoder()

    func search(query: String) -> AnyPublisher<MultiSearchResponse, Error> {
        guard let esc = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "\(baseURL)?api_key=\(apiKey)&query=\(esc)")
        else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .timeout(.seconds(10), scheduler: DispatchQueue.global())
            .decode(type: MultiSearchResponse.self, decoder: decoder)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
