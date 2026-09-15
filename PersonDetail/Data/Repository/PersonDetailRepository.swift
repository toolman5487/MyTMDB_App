//
//  PersonDetailRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonDetailRepository

nonisolated final class PersonDetailRepository: PersonDetailProviding {

    // MARK: - Properties

    private let network: NetworkServicing
    private let localization: AppLocalization

    // MARK: - Initialization

    init(
        network: NetworkServicing,
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    // MARK: - PersonDetailProviding

    func person(id: Int) async throws -> Person {
        let dto: PersonDetailDTO = try await network.get(
            path: APIConfig.Person.detail(id: id),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func combinedCredits(personID: Int) async throws -> PersonCredits {
        let dto: PersonCreditsDTO = try await network.get(
            path: APIConfig.Person.combinedCredits(id: personID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func movieCredits(personID: Int) async throws -> PersonCredits {
        let dto: PersonCreditsDTO = try await network.get(
            path: APIConfig.Person.movieCredits(id: personID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func tvCredits(personID: Int) async throws -> PersonCredits {
        let dto: PersonCreditsDTO = try await network.get(
            path: APIConfig.Person.tvCredits(id: personID),
            queryItems: localizedQueryItems
        )
        return dto.mapped()
    }

    func images(personID: Int) async throws -> PersonImages {
        let dto: PersonImagesDTO = try await network.get(
            path: APIConfig.Person.images(id: personID),
            queryItems: []
        )
        return dto.mapped()
    }

    func externalIDs(personID: Int) async throws -> PersonExternalIDs {
        let dto: PersonExternalIDsDTO = try await network.get(
            path: APIConfig.Person.externalIDs(id: personID),
            queryItems: []
        )
        return dto.mapped()
    }

    // MARK: - Private Helpers

    private var localizedQueryItems: [URLQueryItem] {
        [URLQueryItem(name: "language", value: localization.languageParameter)]
    }
}
