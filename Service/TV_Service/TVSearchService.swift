//
//  TVSearchService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/22.
//

import Foundation
import Combine

protocol TVSearchServiceProtocol {
    func searchTV(query: String, page: Int) -> AnyPublisher<[TVShow], Error>
}

final class TVSearchService: TVSearchServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL

    func searchTV(query: String, page: Int) -> AnyPublisher<[TVShow], Error> {
        guard let queryEncoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        let urlString = "\(baseURL)/search/tv?api_key=\(apiKey)&language=zh-TW&page=\(page)&query=\(queryEncoded)"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TVSearchResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
