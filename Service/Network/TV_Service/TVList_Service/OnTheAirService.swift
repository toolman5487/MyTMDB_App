//
//  OnTheAirService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/23.
//

import Foundation
import Combine

protocol OnTheAirServiceProtocol {
    func fetchOnTheAir() -> AnyPublisher<[TVListShow], Error>
}

final class OnTheAirService: OnTheAirServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    
    func fetchOnTheAir() -> AnyPublisher<[TVListShow], Error> {
        let urlString = "\(baseURL)/tv/on_the_air?api_key=\(apiKey)&language=zh-TW"
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
