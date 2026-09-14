//
//  MediaGenreRepository.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaGenreRepository

nonisolated final class MediaGenreRepository: MediaGenreProviding {

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

    // MARK: - MediaGenreProviding

    func genres(kind: MediaKind) async throws -> [MediaGenre] {
        let dto: MediaGenreListDTO = try await network.get(
            path: APIConfig.genreList(kind: kind),
            queryItems: [
                URLQueryItem(name: "language", value: localization.languageParameter)
            ]
        )

        return dto.mapped()
    }
}
