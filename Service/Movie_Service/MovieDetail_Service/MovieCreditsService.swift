//
//  MovieCreditsService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/14.
//

import Foundation
import Combine

protocol MovieCreditsServiceProtocol {
    func fetchMovieCredits(movieId: Int) -> AnyPublisher<MovieCreditsResponse, Error>
}

final class MovieCreditsService: MovieCreditsServiceProtocol {
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL

    func fetchMovieCredits(movieId: Int) -> AnyPublisher<MovieCreditsResponse, Error> {
        let urlString = "\(baseURL)/movie/\(movieId)/credits?api_key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieCreditsResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
