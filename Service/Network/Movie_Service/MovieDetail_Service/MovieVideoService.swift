//
//  MovieVideoService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/27.
//


import Foundation
import Combine

protocol MovieVideoServiceProtocol {
    func fetchVideos(movieId: Int) -> AnyPublisher<[MovieVideo], Error>
}

final class MovieVideoService: MovieVideoServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    
    func fetchVideos(movieId: Int) -> AnyPublisher<[MovieVideo], Error> {
        guard let url = URL(string: "\(baseURL)/movie/\(movieId)/videos?api_key=\(apiKey)") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieVideosResponse.self, decoder: JSONDecoder())
            .map { $0.results }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}

