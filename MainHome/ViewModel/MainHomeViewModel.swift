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
    case failed(ErrorMessage)
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
                .filter { !$0.contents.isEmpty }
                .map(MainHomeSectionItem.init(section:))

            state = visibleSections.isEmpty ? .empty : .loaded(visibleSections)
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - MainHomeSectionItem

nonisolated struct MainHomeSectionItem: Sendable, Equatable, Identifiable {
    let id: MainHomeContentCategory
    let category: MainHomeContentCategory
    let title: String
    let contents: [MainHomeContentItem]

    init(section: MainHomeContentSection) {
        self.id = section.category
        self.category = section.category
        self.title = section.category.title
        self.contents = section.contents.map { content in
            MainHomeContentItem(
                content: content,
                mediaType: section.category.mediaType
            )
        }
    }
}

// MARK: - MainHomeContentItem

nonisolated struct MainHomeContentItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let mediaType: MainHomeMediaType
    let mediaTypeText: String
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let dateText: String
    let scoreText: String

    init(content: MainHomeContent, mediaType: MainHomeMediaType) {
        self.id = content.id
        self.title = content.title
        self.mediaType = mediaType
        self.mediaTypeText = mediaType.title
        self.overview = content.overview
        self.posterURL = content.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
        self.backdropURL = content.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.dateText = content.primaryDate?.isEmpty == false ? content.primaryDate ?? "" : "尚未公布"
        self.scoreText = String(format: "%.1f", content.voteAverage)
    }
}

// MARK: - MainHomeContentCategory Presentation

private extension MainHomeContentCategory {

    var title: String {
        switch self {
        case .trendingMovies:
            return "今日趨勢電影"

        case .trendingTV:
            return "今日趨勢影集"

        case .popularMovies:
            return "熱門電影"

        case .popularTV:
            return "熱門影集"

        case .nowPlayingMovies:
            return "現正熱映"

        case .onTheAirTV:
            return "播出中影集"

        case .upcomingMovies:
            return "即將上映"

        case .airingTodayTV:
            return "今日播出影集"

        case .topRatedMovies:
            return "高分電影"

        case .topRatedTV:
            return "高分影集"
        }
    }
}

// MARK: - MainHomeMediaType Presentation

private extension MainHomeMediaType {

    var title: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "影集"
        }
    }
}
