//
//  AppIntentEntityLookupService.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/28.
//

import Foundation

// MARK: - AppIntentEntityLookupServicing

nonisolated protocol AppIntentEntityLookupServicing: Sendable {
    func fetchMovieEntity(id: Int) async throws -> MovieEntity
    func fetchTVSeriesEntity(id: Int) async throws -> TVSeriesEntity
}

// MARK: - AppIntentEntityLookupService

nonisolated final class AppIntentEntityLookupService: AppIntentEntityLookupServicing {
    private let network: NetworkServicing
    private let localization: AppLocalization

    init(
        network: NetworkServicing = NetworkService(),
        localization: AppLocalization = .current
    ) {
        self.network = network
        self.localization = localization
    }

    func fetchMovieEntity(id: Int) async throws -> MovieEntity {
        let response: MovieEntityResponse = try await network.get(
            path: APIConfig.Movie.detail(id: id),
            queryItems: localizedQueryItems
        )

        return MovieEntity(response: response)
    }

    func fetchTVSeriesEntity(id: Int) async throws -> TVSeriesEntity {
        let response: TVSeriesEntityResponse = try await network.get(
            path: APIConfig.TV.detail(seriesId: id),
            queryItems: localizedQueryItems
        )

        return TVSeriesEntity(response: response)
    }

    private var localizedQueryItems: [URLQueryItem] {
        [
            URLQueryItem(name: "language", value: localization.languageParameter)
        ]
    }
}

// MARK: - Responses

private struct MovieEntityResponse: Decodable, Sendable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let releaseDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case originalTitle = "original_title"
        case overview
        case posterPath = "poster_path"
        case releaseDate = "release_date"
    }
}

private struct TVSeriesEntityResponse: Decodable, Sendable {
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let firstAirDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case originalName = "original_name"
        case overview
        case posterPath = "poster_path"
        case firstAirDate = "first_air_date"
    }
}

private extension MovieEntity {
    init(response: MovieEntityResponse) {
        self.init(
            id: response.id,
            title: response.title,
            originalTitle: response.originalTitle,
            overview: response.overview?.isEmpty == false ? response.overview : nil,
            posterPath: response.posterPath,
            releaseYear: Self.releaseYear(from: response.releaseDate)
        )
    }
}

private extension TVSeriesEntity {
    init(response: TVSeriesEntityResponse) {
        self.init(
            id: response.id,
            name: response.name,
            originalName: response.originalName,
            overview: response.overview?.isEmpty == false ? response.overview : nil,
            posterPath: response.posterPath,
            firstAirYear: Self.firstAirYear(from: response.firstAirDate)
        )
    }
}
