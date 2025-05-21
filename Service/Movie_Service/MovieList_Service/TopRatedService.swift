//
//  TopRatedService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/21.
//

import Foundation

import Combine

protocol TopRatedServiceProtocol {
    func fetchTopRated() -> AnyPublisher<[MovieSummary], Error>
}

final class TopRatedService: TopRatedServiceProtocol {
    func fetchTopRated() -> AnyPublisher<[MovieSummary], Error> {
        let urlString = "\(TMDB.baseURL)/movie/top_rated?api_key=\(TMDB.apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieListResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
