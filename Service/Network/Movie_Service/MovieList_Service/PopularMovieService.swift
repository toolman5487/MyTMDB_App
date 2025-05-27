//
//  PopularMovieService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/21.
//

import Foundation
import Combine

protocol PopularMovieServiceProtocol {
    func fetchPopular() -> AnyPublisher<[MovieSummary], Error>
}

final class PopularMovieService: PopularMovieServiceProtocol {
    func fetchPopular() -> AnyPublisher<[MovieSummary], Error> {
        let urlString = "\(TMDB.baseURL)/movie/popular?api_key=\(TMDB.apiKey)&language=zh-TW"
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
