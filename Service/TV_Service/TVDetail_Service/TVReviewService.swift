//
//  TVReviewService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/19.
//

import Foundation
import Combine

enum TVError: Error {
    case urlError
    case httpError(Int)
}

protocol TVReviewServiceProtocol {
    func fetchAllReviews(tvId: Int) -> AnyPublisher<[Review], Error>
}

final class TVReviewService: TVReviewServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func fetchPage(tvId: Int, page: Int) -> AnyPublisher<ReviewResponse, Error> {
        let urlString = "\(baseURL)/tv/\(tvId)/reviews?api_key=\(apiKey)&page=\(page)"
        guard let url = URL(string: urlString) else {
            return Fail(error: TVError.urlError).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        return session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let resp = output.response as? HTTPURLResponse,
                      200..<300 ~= resp.statusCode else {
                    throw TVError.httpError((output.response as? HTTPURLResponse)?.statusCode ?? -1)
                }
                return output.data
            }
            .decode(type: ReviewResponse.self, decoder: {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let isoFormatter = ISO8601DateFormatter()
                    isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let date = isoFormatter.date(from: dateString) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(in: container,
                        debugDescription: "Cannot parse date string \(dateString)")
                }
                return decoder
            }())
            .eraseToAnyPublisher()
    }
    
    func fetchAllReviews(tvId: Int) -> AnyPublisher<[Review], Error> {
        return fetchPage(tvId: tvId, page: 1)
            .flatMap { firstResponse -> AnyPublisher<[Review], Error> in
                let total = firstResponse.totalPages
                guard total > 1 else {
                    return Just(firstResponse.results)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                let remaining = (2...total).map {
                    self.fetchPage(tvId: tvId, page: $0)
                        .map(\.results)
                        .eraseToAnyPublisher()
                }
                return Publishers.MergeMany(remaining)
                    .collect()
                    .map { pages in
                        firstResponse.results + pages.flatMap { $0 }
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
