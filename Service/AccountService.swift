//
//  AccountService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import Combine

protocol AccountServiceProtocol {
    func fetchAccount(sessionId: String) -> AnyPublisher<Account, Error>
}

final class AccountService: AccountServiceProtocol {
    private let apiKey = TMDB.apiKey
    func fetchAccount(sessionId: String) -> AnyPublisher<Account, Error> {
        let url = URL(string: "\(TMDB.baseURL)/account?api_key=\(TMDB.apiKey)&session_id=\(sessionId)")!
        return URLSession.shared.dataTaskPublisher(for: url)
          .map(\.data)
          .decode(type: Account.self, decoder: JSONDecoder())
          .receive(on: DispatchQueue.main)
          .eraseToAnyPublisher()
    }
}
