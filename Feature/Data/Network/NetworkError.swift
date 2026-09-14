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
            return "網址格式錯誤"

        case .invalidResponse:
            return "伺服器回應異常"

        case .requestFailed(let code):
            return "網路請求失敗（\(code.rawValue)）"

        case .encodingFailed:
            return "請求資料編碼失敗"

        case .httpError(let statusCode):
            return "HTTP 錯誤（\(statusCode)）"

        case .apiError(_, let apiCode, let message):
            let apiCodeText = apiCode.map { "（\($0)）" } ?? ""
            return message.isEmpty ? "API 回傳錯誤\(apiCodeText)" : "API 回傳錯誤\(apiCodeText)：\(message)"

        case .decodingFailed:
            return "資料解析失敗"
        }
    }
}
