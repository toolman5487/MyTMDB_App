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
    func fetchSeasonDetail(tvId: Int, seasonNumber: Int) -> AnyPublisher<SeasonDetailResponse, Error>
    func fetchEpisodeDetail(tvId: Int, seasonNumber: Int, episodeNumber: Int) -> AnyPublisher<EpisodeModel, Error>
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

    func fetchSeasonDetail(tvId: Int, seasonNumber: Int) -> AnyPublisher<SeasonDetailResponse, Error> {
        let urlString = "\(TMDB.baseURL)/tv/\(tvId)/season/\(seasonNumber)?api_key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: SeasonDetailResponse.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    func fetchEpisodeDetail(tvId: Int, seasonNumber: Int, episodeNumber: Int) -> AnyPublisher<EpisodeModel, Error> {
        let urlString = "\(TMDB.baseURL)/tv/\(tvId)/season/\(seasonNumber)/episode/\(episodeNumber)?api_key=\(apiKey)&language=zh-TW"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: EpisodeModel.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}
