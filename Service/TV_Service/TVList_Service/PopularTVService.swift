//
//  PopularTVService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/23.
//

import Foundation
import Combine

protocol PopularTVServiceProtocol {
    func fetchPopularTV() -> AnyPublisher<[TVListShow], Error>
}

final class PopularTVService: PopularTVServiceProtocol {
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL

    func fetchPopularTV() -> AnyPublisher<[TVListShow], Error> {
        let urlString = "\(baseURL)/tv/popular?api_key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TVListResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
