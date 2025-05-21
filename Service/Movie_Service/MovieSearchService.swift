//
//  MovieSearchService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//


import Foundation
import Combine

protocol MovieSearchServiceProtocol {
    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error>
}

final class MovieSearchService: MovieSearchServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func fetchPage(query: String, page: Int) -> AnyPublisher<MovieSearchResponse, Error> {
        let urlStringBase = "\(baseURL)/search/movie?api_key=\(apiKey)&language=zh-TW&page=\(page)&query="
        if let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: urlStringBase + encodedQuery) {
            return session.dataTaskPublisher(for: url)
                .map(\.data)
                .decode(type: MovieSearchResponse.self, decoder: JSONDecoder())
                .eraseToAnyPublisher()
        } else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
    }

    func searchMovies(query: String, page: Int) -> AnyPublisher<[Movie], Error> {
        return fetchPage(query: query, page: page)
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
