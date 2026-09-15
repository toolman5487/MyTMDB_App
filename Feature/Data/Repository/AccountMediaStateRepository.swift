//
//  AccountMediaStateRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaStateRepository

nonisolated final class AccountMediaStateRepository: AccountMediaStateProviding {

    // MARK: - Properties

    private let network: NetworkServicing

    // MARK: - Initialization

    init(network: NetworkServicing) {
        self.network = network
    }

    // MARK: - AccountMediaStateProviding

    func mediaState(
        kind: MediaKind,
        mediaID: Int,
        sessionID: String
    ) async throws -> AccountMediaState {
        let dto: AccountMediaStatesDTO = try await network.get(
            path: APIConfig.accountStates(kind: kind, id: mediaID),
            queryItems: Self.authenticatedQueryItems(sessionID: sessionID)
        )

        return dto.mapped()
    }

    func updateFavorite(
        accountID: Int,
        sessionID: String,
        kind: MediaKind,
        mediaID: Int,
        isFavorite: Bool
    ) async throws -> AccountActionResult {
        let dto: AccountStatusResponseDTO = try await network.post(
            path: APIConfig.Account.favorite(accountID: accountID),
            queryItems: Self.authenticatedQueryItems(sessionID: sessionID),
            body: AccountFavoriteRequestDTO(
                mediaType: kind,
                mediaID: mediaID,
                favorite: isFavorite
            )
        )

        return dto.mapped()
    }

    func submitRating(
        sessionID: String,
        target: AccountMediaRatingTarget,
        value: Double
    ) async throws -> AccountActionResult {
        let dto: AccountStatusResponseDTO = try await network.post(
            path: Self.ratingPath(for: target),
            queryItems: Self.authenticatedQueryItems(sessionID: sessionID),
            body: AccountRatingRequestDTO(value: AccountMediaRatingValue.normalized(value))
        )

        return dto.mapped()
    }

    func deleteRating(
        sessionID: String,
        target: AccountMediaRatingTarget
    ) async throws -> AccountActionResult {
        let emptyBody: (any Encodable)? = nil

        let dto: AccountStatusResponseDTO = try await network.delete(
            path: Self.ratingPath(for: target),
            queryItems: Self.authenticatedQueryItems(sessionID: sessionID),
            body: emptyBody
        )

        return dto.mapped()
    }

    // MARK: - Private Methods

    private static func authenticatedQueryItems(sessionID: String) -> [URLQueryItem] {
        [
            URLQueryItem(name: "session_id", value: sessionID)
        ]
    }

    private static func ratingPath(for target: AccountMediaRatingTarget) -> String {
        switch target {
        case .movie(let id):
            return APIConfig.Movie.rating(id: id)

        case .tv(let seriesID):
            return APIConfig.TV.rating(seriesID: seriesID)

        case .episode(let seriesID, let seasonNumber, let episodeNumber):
            return APIConfig.TV.episodeRating(
                seriesID: seriesID,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber
            )
        }
    }
}
