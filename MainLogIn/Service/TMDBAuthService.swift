//
//  TMDBAuthService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation

// MARK: - Protocol

protocol TMDBAuthServicing {
    func login(username: String, password: String) async throws -> String
}

// MARK: - TMDBAuthService

final class TMDBAuthService: TMDBAuthServicing {

    // MARK: - Properties

    private let apiKey = TMDB.apiKey
    private let baseURL = "\(TMDB.baseURL)/authentication"
    private let decoder = JSONDecoder()
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = ["__QUIC__": false]
        return URLSession(configuration: config)
    }()

    // MARK: - Public Methods

    func login(username: String, password: String) async throws -> String {
        let token = try await requestToken()
        let validatedToken = try await validate(token: token, username: username, password: password)
        return try await createSession(token: validatedToken)
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        var lastError: Error?

        for _ in 0..<2 {
            do {
                return try await performRequest(path: path, method: method, body: body)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private func performRequest<T: Decodable>(
        path: String,
        method: String,
        body: Data?
    ) async throws -> T {
        let url = URL(string: "\(baseURL)\(path)?api_key=\(apiKey)")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method

        if let body {
            urlRequest.httpBody = body
            urlRequest.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        let (data, _) = try await session.data(for: urlRequest)
        return try decoder.decode(T.self, from: data)
    }

    private func requestToken() async throws -> String {
        let response: TokenResponse = try await request(path: "/token/new")
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return response.request_token
    }

    private func validate(token: String, username: String, password: String) async throws -> String {
        let credentials = try JSONEncoder().encode([
            "username": username,
            "password": password,
            "request_token": token
        ])
        let response: ValidateResponse = try await request(
            path: "/token/validate_with_login",
            method: "POST",
            body: credentials
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return token
    }

    private func createSession(token: String) async throws -> String {
        let sessionBody = try JSONEncoder().encode(["request_token": token])
        let response: SessionResponse = try await request(
            path: "/session/new",
            method: "POST",
            body: sessionBody
        )
        guard response.success else {
            throw URLError(.userAuthenticationRequired)
        }
        return response.session_id
    }
}
