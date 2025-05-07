//
//  TVDetailService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/7.
//

import Foundation
import Combine


protocol TVDetailServiceProtocol {
    func fetchTVDetail(id: Int) -> AnyPublisher<TVDetailModel, Error>
}

final class TVDetailService: TVDetailServiceProtocol {
    private let apiKey = TMDB.apiKey
    func fetchTVDetail(id: Int) -> AnyPublisher<TVDetailModel, Error> {
        guard let url = URL(string: "\(TMDB.baseURL)/tv/\(id)?api_key=\(TMDB.apiKey)&language=zh-TW") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TVDetailModel.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
