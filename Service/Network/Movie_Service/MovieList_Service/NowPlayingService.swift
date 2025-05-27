//
//  NowPlayingService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/21.
//

import Foundation
import Combine

protocol NowPlayingServiceProtocol {
    func fetchNowPlaying() -> AnyPublisher<[MovieSummary], Error>
}

final class NowPlayingService: NowPlayingServiceProtocol {
    func fetchNowPlaying() -> AnyPublisher<[MovieSummary], Error> {
        let urlString = "\(TMDB.baseURL)/movie/now_playing?api_key=\(TMDB.apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: MovieListResponse.self, decoder: JSONDecoder())
            .map(\.results)
            .eraseToAnyPublisher()
    }
}
