//
//  FavoriteService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/15.
//

import Foundation
import Combine

protocol FavoriteServiceProtocol {
    func toggleFavorite(mediaType: String,mediaId: Int,favorite: Bool,accountId: Int,sessionId: String) -> AnyPublisher<FavoriteResponse, Error>
    func fetchFavoriteState( mediaType: String, mediaId: Int,sessionId: String ) -> AnyPublisher<AccountState, Error>
}

final class FavoriteService: FavoriteServiceProtocol {

    func toggleFavorite(
        mediaType: String,
        mediaId: Int,
        favorite: Bool,
        accountId: Int,
        sessionId: String) -> AnyPublisher<FavoriteResponse, Error> {
        let urlString = "\(TMDB.baseURL)/account/\(accountId)/favorite?api_key=\(TMDB.apiKey)&session_id=\(sessionId)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "media_type": mediaType,
            "media_id": mediaId,
            "favorite": favorite
        ]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return URLSession.shared.dataTaskPublisher(for: req)
            .map(\.data)
            .decode(type: FavoriteResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchFavoriteState(mediaType: String, mediaId: Int, sessionId: String) -> AnyPublisher<AccountState, Error> {
        let urlString = "\(TMDB.baseURL)/\(mediaType)/\(mediaId)/account_states?api_key=\(TMDB.apiKey)&session_id=\(sessionId)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: AccountState.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
