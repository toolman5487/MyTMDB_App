//
//  FavoriteService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/15.
//

import Foundation
import Combine

protocol FavoriteServiceProtocol {
    
    func fetchFavoriteState(mediaType: String, mediaId: Int, sessionId: String) -> AnyPublisher<AccountState, Error>
    
    func toggleFavorite(mediaType: String,mediaId: Int,favorite: Bool,accountId: Int,sessionId: String) -> AnyPublisher<FavoriteResponse, Error>
    
    func rate(mediaType: String, mediaId: Int, value: Double, sessionId: String) -> AnyPublisher<Void, Error>
    
    func fetchAccountState(movieId: Int, sessionId: String) -> AnyPublisher<MovieAccountState, Error>
}

final class FavoriteService: FavoriteServiceProtocol {
    
    func rate(mediaType: String, mediaId: Int, value: Double, sessionId: String) -> AnyPublisher<Void, Error> {
        let urlString = "\(TMDB.baseURL)/\(mediaType)/\(mediaId)/rating?api_key=\(TMDB.apiKey)&session_id=\(sessionId)"
        guard let url = URL(string: urlString) else {
            return Fail<Void, Error>(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["value": value]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: body)
            urlRequest.httpBody = data
            print("Rate HTTP Body:", String(data: data, encoding: .utf8) ?? "")
        } catch {
            return Fail<Void, Error>(error: error).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: urlRequest)
            .tryMap { data, response in
                return ()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
        
        
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
                var urlRequest = URLRequest(url: url)
                urlRequest.httpMethod = "POST"
                urlRequest.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
                let body: [String: Any] = [
                    "media_type": mediaType,
                    "media_id": mediaId,
                    "favorite": favorite
                ]
                do {
                    let data = try JSONSerialization.data(withJSONObject: body)
                    urlRequest.httpBody = data
                    print("HTTP Body:", String(data: data, encoding: .utf8) ?? "")
                } catch {
                    print("Serialization error:", error)
                }
                return URLSession.shared.dataTaskPublisher(for: urlRequest)
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
    
    func fetchAccountState(movieId: Int, sessionId: String) -> AnyPublisher<MovieAccountState, Error> {
        let urlString = "\(TMDB.baseURL)/movie/\(movieId)/account_states?api_key=\(TMDB.apiKey)&session_id=\(sessionId)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieAccountState.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
