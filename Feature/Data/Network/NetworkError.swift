//
//  NetworkError.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - NetworkError

nonisolated enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case requestFailed(URLError.Code)
    case encodingFailed
    case httpError(statusCode: Int)
    case apiError(statusCode: Int, apiCode: Int?, message: String)
    case decodingFailed

    var statusCode: Int? {
        switch self {
        case .httpError(let statusCode), .apiError(let statusCode, _, _):
            return statusCode

        case .invalidURL, .invalidResponse, .requestFailed, .encodingFailed, .decodingFailed:
            return nil
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"

        case .invalidResponse:
            return "Invalid server response"

        case .requestFailed(let code):
            return "Request failed (URLError \(code.rawValue))"

        case .encodingFailed:
            return "Request body encoding failed"

        case .httpError(let statusCode):
            return "HTTP error \(statusCode)"

        case .apiError(_, let apiCode, let message):
            let apiCodeText = apiCode.map { " (code \($0))" } ?? ""
            return message.isEmpty ? "TMDB API error\(apiCodeText)" : "TMDB API error\(apiCodeText): \(message)"

        case .decodingFailed:
            return "Response decoding failed"
        }
    }
}
