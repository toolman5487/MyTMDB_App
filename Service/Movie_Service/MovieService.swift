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
    private let apiKey = "a704c1ee4f1214cebbb5a43c01986dbb"
    func fetchMovieDetail(id: Int) -> AnyPublisher<MovieDetailModel, Error> {
        guard let url = URL(string: "https://api.themoviedb.org/3/movie/\(id)?api_key=\(apiKey)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieDetailModel.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
