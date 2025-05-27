//
//  MovieReviewService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/16.
//

import Foundation
import Combine

enum MovieError: Error {
    case urlError
    case httpError(Int)
}

protocol MovieReviewServiceProtocol {
    func fetchAllReviews(movieId: Int) -> AnyPublisher<[Review], Error>
}

final class MovieReviewService: MovieReviewServiceProtocol {
    
    private let apiKey = TMDB.apiKey
    private let baseURL = TMDB.baseURL
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private func fetchPage(movieId: Int, page: Int) -> AnyPublisher<ReviewResponse, Error> {
        let urlString = "\(baseURL)/movie/\(movieId)/reviews?api_key=\(apiKey)&page=\(page)"
        guard let url = URL(string: urlString) else {
            return Fail(error: MovieError.urlError).eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        return session.dataTaskPublisher(for: request)
            .tryMap { output in
                guard let resp = output.response as? HTTPURLResponse,
                      200..<300 ~= resp.statusCode else {
                    throw MovieError.httpError((output.response as? HTTPURLResponse)?.statusCode ?? -1)
                }
                return output.data
            }
            .decode(type: ReviewResponse.self, decoder: {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return decoder
            }())
            .eraseToAnyPublisher()
    }
    
    func fetchAllReviews(movieId: Int) -> AnyPublisher<[Review], Error> {
        return fetchPage(movieId: movieId, page: 1)
            .flatMap { firstResponse -> AnyPublisher<[Review], Error> in
                print("First page fetched: page=1, reviews count=", firstResponse.results.count, " totalPages=", firstResponse.totalPages)
                let total = firstResponse.totalPages
                guard total > 1 else {
                    print("Only one page, total reviews=", firstResponse.results.count)
                    return Just(firstResponse.results)
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                let remaining = (2...total).map { self.fetchPage(movieId: movieId, page: $0)
                    .map(\.results)
                    .eraseToAnyPublisher() }
                print("Preparing to fetch remaining pages: ", Array(2...total))
                return Publishers.MergeMany(remaining)
                    .collect()
                    .handleEvents(receiveOutput: { pages in
                        print("Remaining pages fetched: ", pages.map { $0.count })
                    })
                    .map { pages in
                        firstResponse.results + pages.flatMap { $0 }
                    }
                    .eraseToAnyPublisher()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
