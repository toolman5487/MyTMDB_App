//
//  AllTrendingSerivce.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//


import Foundation
import Combine

protocol AllTrendingServiceProtocol {
    func fetchTrendingAll(timeWindow: String) -> AnyPublisher<[TrendingItem], Error>
}

final class AllTrendingService: AllTrendingServiceProtocol {
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTrendingAll(timeWindow: String) -> AnyPublisher<[TrendingItem], Error> {
        let urlString = "\(baseURL)/trending/all/\(timeWindow)?api_key=\(apiKey)&language=zh-TW&page=1"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TrendingResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
