//
//  MainHomeViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/29.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum MainHomeViewState: Equatable {
    case idle
    case loading
    case loaded([MainHomeSectionItem])
    case empty
    case failed(message: String)
}

// MARK: - MainHomeViewModel

@MainActor
@Observable
final class MainHomeViewModel {

    // MARK: - Properties

    private(set) var state: MainHomeViewState = .idle

    private let service: MainHomeServicing

    // MARK: - Initialization

    init(service: MainHomeServicing = MainHomeService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadHome() async {
        state = .loading

        do {
            let sections = try await service.fetchHomeSections()
            let visibleSections = sections
                .filter { !$0.movies.isEmpty }
                .map(MainHomeSectionItem.init(section:))

            state = visibleSections.isEmpty ? .empty : .loaded(visibleSections)
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }
}

// MARK: - MainHomeSectionItem

nonisolated struct MainHomeSectionItem: Sendable, Equatable, Identifiable {
    let id: MainHomeMovieCategory
    let category: MainHomeMovieCategory
    let title: String
    let movies: [MainHomeMovieItem]

    init(section: MainHomeMovieSection) {
        self.id = section.category
        self.category = section.category
        self.title = section.category.title
        self.movies = section.movies.map(MainHomeMovieItem.init(movie:))
    }
}

// MARK: - MainHomeMovieItem

nonisolated struct MainHomeMovieItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let releaseDateText: String
    let scoreText: String

    init(movie: MainHomeMovie) {
        self.id = movie.id
        self.title = movie.title
        self.overview = movie.overview
        self.posterURL = movie.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.backdropURL = movie.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.releaseDateText = movie.releaseDate?.isEmpty == false ? movie.releaseDate ?? "" : "尚未公布"
        self.scoreText = String(format: "%.1f", movie.voteAverage)
    }
}

// MARK: - MainHomeMovieCategory Presentation

private extension MainHomeMovieCategory {

    var title: String {
        switch self {
        case .trendingToday:
            return "今日趨勢"

        case .popular:
            return "熱門電影"

        case .nowPlaying:
            return "現正熱映"

        case .upcoming:
            return "即將上映"

        case .topRated:
            return "高分電影"
        }
    }
}
