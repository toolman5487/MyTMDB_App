//
//  TMDBAuthService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//


import Foundation
import Combine

final class TMDBAuthService {
    private let apiKey = TMDB.apiKey
    private let baseURL = "\(TMDB.baseURL)/authentication"
    private let decoder = JSONDecoder()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = ["__QUIC__": false]
        return URLSession(configuration: config)
    }()

    private func request<T: Decodable>(path: String,method: String = "GET",body: Data? = nil) -> AnyPublisher<T, Error> {
        let url = URL(string: "\(baseURL)\(path)?api_key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let body = body {
            request.httpBody = body
            request.setValue("application/json;charset=utf-8",forHTTPHeaderField: "Content-Type")
        }
        return session.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: T.self, decoder: decoder)
            .retry(1)
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("TMDBAuthService request \(path) failed:", error)
                }
            })
            .eraseToAnyPublisher()
    }

    private func requestTokenPublisher() -> AnyPublisher<String, Error> {
        request(path: "/token/new")
            .compactMap { (resp: TokenResponse) in
                resp.success ? resp.request_token : nil
            }
            .eraseToAnyPublisher()
    }

    private func validatePublisher(token: String, username: String, password: String) -> AnyPublisher<String, Error> {
        let credentials = try? JSONEncoder().encode([
            "username": username,
            "password": password,
            "request_token": token
        ])
        return request(path: "/token/validate_with_login", method: "POST", body: credentials)
            .tryMap { (resp: ValidateResponse) in
                guard resp.success else { throw URLError(.userAuthenticationRequired) }
                return token
            }
            .eraseToAnyPublisher()
    }

    private func sessionPublisher(token: String) -> AnyPublisher<String, Error> {
        let sessionBody = try? JSONEncoder().encode(["request_token": token])
        return request(path: "/session/new", method: "POST", body: sessionBody)
            .compactMap { (resp: SessionResponse) in
                resp.success ? resp.session_id : nil
            }
            .eraseToAnyPublisher()
    }

    func loginPublisher(username: String, password: String) -> AnyPublisher<String, Error> {
        requestTokenPublisher()
            .flatMap { token in
                self.validatePublisher(token: token, username: username, password: password)
            }
            .flatMap { token in
                self.sessionPublisher(token: token)
            }
            .receive(on: DispatchQueue.main)
            .retry(1)
            .handleEvents(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("TMDBAuthService loginPublisher failed:", error)
                }
            })
            .eraseToAnyPublisher()
    }
}
