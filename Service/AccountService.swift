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
    func fetchFavoriteTV(accountId: Int, sessionId: String) -> AnyPublisher<[FavoriteTVItem], Error>
}

final class AccountService: AccountServiceProtocol {
    private let apiKey = TMDB.apiKey

    private func makeFavoritesURL(mediaType: String, accountId: Int, sessionId: String) -> URL? {
        let urlString = "\(TMDB.baseURL)/account/\(accountId)/favorite/\(mediaType)?api_key=\(apiKey)&session_id=\(sessionId)&language=zh-TW"
        return URL(string: urlString)
    }

    func fetchAccount(sessionId: String) -> AnyPublisher<Account, Error> {
        let url = URL(string: "\(TMDB.baseURL)/account?api_key=\(TMDB.apiKey)&session_id=\(sessionId)")!
        return URLSession.shared.dataTaskPublisher(for: url)
          .map(\.data)
          .decode(type: Account.self, decoder: JSONDecoder())
          .receive(on: DispatchQueue.main)
          .eraseToAnyPublisher()
    }

    func fetchFavoriteMovies(accountId: Int, sessionId: String) -> AnyPublisher<[FavoriteMovieItem], Error> {
        guard let url = makeFavoritesURL(mediaType: "movies", accountId: accountId, sessionId: sessionId) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: FavoriteMoviesResponse.self, decoder: JSONDecoder())
            .map { $0.results }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFavoriteTV(accountId: Int, sessionId: String) -> AnyPublisher<[FavoriteTVItem], Error> {
        guard let url = makeFavoritesURL(mediaType: "tv", accountId: accountId, sessionId: sessionId) else {
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
