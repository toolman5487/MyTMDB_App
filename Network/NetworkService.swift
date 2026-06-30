//
//  NetworkService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import Foundation

// MARK: - HTTPMethod

enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Protocol

protocol NetworkServicing {
    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws -> T

    func post<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: (any Encodable)?
    ) async throws -> T

    func put<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: (any Encodable)?
    ) async throws -> T

    func patch<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: (any Encodable)?
    ) async throws -> T

    func delete<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        body: (any Encodable)?
    ) async throws -> T

    func delete(
        path: String,
        queryItems: [URLQueryItem]
    ) async throws
}

extension NetworkServicing {

    func get<T: Decodable>(path: String) async throws -> T {
        try await get(path: path, queryItems: [])
    }

    func post<T: Decodable>(
        path: String,
        body: (any Encodable)?
    ) async throws -> T {
        try await post(path: path, queryItems: [], body: body)
    }

    func put<T: Decodable>(
        path: String,
        body: (any Encodable)?
    ) async throws -> T {
        try await put(path: path, queryItems: [], body: body)
    }

    func patch<T: Decodable>(
        path: String,
        body: (any Encodable)?
    ) async throws -> T {
        try await patch(path: path, queryItems: [], body: body)
    }

    func delete(path: String) async throws {
        try await delete(path: path, queryItems: [])
    }
}

// MARK: - NetworkService

final class NetworkService: NetworkServicing {

    // MARK: - Properties

    private let baseURL: String
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init(
        baseURL: String = APIConfig.tmdbBaseURL,
        session: URLSession = NetworkService.makeSession(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
        self.encoder = encoder
    }

    // MARK: - Public Methods

    func get<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        try await request(
            path: path,
            method: .get,
            queryItems: queryItems
        )
    }

    func post<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> T {
        try await request(
            path: path,
            method: .post,
            queryItems: queryItems,
            body: body
        )
    }

    func put<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> T {
        try await request(
            path: path,
            method: .put,
            queryItems: queryItems,
            body: body
        )
    }

    func patch<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> T {
        try await request(
            path: path,
            method: .patch,
            queryItems: queryItems,
            body: body
        )
    }

    func delete<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> T {
        try await request(
            path: path,
            method: .delete,
            queryItems: queryItems,
            body: body
        )
    }

    func delete(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws {
        let _: EmptyResponse = try await delete(
            path: path,
            queryItems: queryItems,
            body: Optional<any Encodable>.none
        )
    }

    // MARK: - Private Methods

    private func request<T: Decodable>(
        path: String,
        method: HTTPMethod,
        queryItems: [URLQueryItem] = [],
        body: (any Encodable)? = nil
    ) async throws -> T {
        let url = try makeURL(path: path, queryItems: queryItems)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue

        if let body {
            do {
                urlRequest.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw NetworkError.encodingFailed
            }
            urlRequest.setValue("application/json;charset=utf-8", forHTTPHeaderField: "Content-Type")
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw NetworkError.requestFailed(error.code)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw makeHTTPError(statusCode: httpResponse.statusCode, data: data)
        }

        if T.self == EmptyResponse.self, data.isEmpty {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    private func makeURL(path: String, queryItems: [URLQueryItem]) throws -> URL {
        var items = queryItems

        if !items.contains(where: { $0.name == "api_key" }) {
            items.insert(URLQueryItem(name: "api_key", value: APIConfig.apiKey), at: 0)
        }

        guard var components = URLComponents(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        components.queryItems = items

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        return url
    }

    private func makeHTTPError(statusCode: Int, data: Data) -> NetworkError {
        guard let response = try? decoder.decode(TMDBErrorResponse.self, from: data),
              let statusMessage = response.statusMessage else {
            return .httpError(statusCode: statusCode)
        }

        return .apiError(
            statusCode: statusCode,
            apiCode: response.statusCode,
            message: statusMessage
        )
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.connectionProxyDictionary = ["__QUIC__": false]
        return URLSession(configuration: config)
    }
}

// MARK: - Helpers

private struct EmptyResponse: Decodable {
    init() {}
}

private struct TMDBErrorResponse: Decodable {
    let success: Bool?
    let statusCode: Int?
    let statusMessage: String?

    enum CodingKeys: String, CodingKey {
        case success
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}

private struct AnyEncodable: Encodable {
    private let encodeValue: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeValue = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeValue(encoder)
    }
}
