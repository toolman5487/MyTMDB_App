//
//  AiringTodayService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/23.
//

import Foundation
import Combine

protocol AiringTodayServiceProtocol {
    func fetchAiringToday() -> AnyPublisher<[TVListShow], Error>
}

final class AiringTodayService: AiringTodayServiceProtocol {
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL

    func fetchAiringToday() -> AnyPublisher<[TVListShow], Error> {
        let urlString = "\(baseURL)/tv/airing_today?api_key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TVListResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
