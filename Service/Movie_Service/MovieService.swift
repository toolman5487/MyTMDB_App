//
//  MovieService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/6.
//

import Foundation
import Combine

protocol MovieServiceProtocol {
    func fetchMovieDetail(id: Int) -> AnyPublisher<MovieDetailModel, Error>
}

final class MovieService: MovieServiceProtocol {
    private let apiKey = TMDB.apiKey
    func fetchMovieDetail(id: Int) -> AnyPublisher<MovieDetailModel, Error> {
        guard let url = URL(string: "\(TMDB.baseURL)/movie/\(id)?api_key=\(TMDB.apiKey)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieDetailModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
