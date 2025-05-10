//
//  AccountService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Combine

protocol AccountServiceProtocol {
    func fetchAccount(sessionId: String) -> AnyPublisher<Account, Error>
    func fetchFavoriteMovies(accountId: Int, sessionId: String) -> AnyPublisher<[FavoriteMovieItem], Error>
    func fetchFavoriteTV(accountId: Int, sessionId: String) -> AnyPublisher<[TVDetailModel], Error>
}

final class AccountService: AccountServiceProtocol {
    private let apiKey = TMDB.apiKey
    func fetchAccount(sessionId: String) -> AnyPublisher<Account, Error> {
        let url = URL(string: "\(TMDB.baseURL)/account?api_key=\(TMDB.apiKey)&session_id=\(sessionId)")!
        return URLSession.shared.dataTaskPublisher(for: url)
          .map(\.data)
          .decode(type: Account.self, decoder: JSONDecoder())
          .receive(on: DispatchQueue.main)
          .eraseToAnyPublisher()
    }

    func fetchFavoriteMovies(accountId: Int, sessionId: String) -> AnyPublisher<[FavoriteMovieItem], Error> {
        guard let url = URL(string: "\(TMDB.baseURL)/account/\(accountId)/favorite/movies?api_key=\(apiKey)&session_id=\(sessionId)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .handleEvents(receiveOutput: { data in
                  print("Service JSON：", String(data: data, encoding: .utf8) ?? "")
              })
            .decode(type: FavoriteMoviesResponseModel.self, decoder: JSONDecoder())
            .map { $0.results }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFavoriteTV(accountId: Int, sessionId: String) -> AnyPublisher<[TVDetailModel], Error> {
        guard let url = URL(string: "\(TMDB.baseURL)/account/\(accountId)/favorite/tv?api_key=\(apiKey)&session_id=\(sessionId)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FavoriteTVResponseModel.self, decoder: JSONDecoder())
            .map { $0.results }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
