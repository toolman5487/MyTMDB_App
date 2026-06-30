//
//  MovieDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum MovieDetailViewState: Equatable {
    case idle
    case loading
    case loaded(MovieDetailItem)
    case failed(ErrorMessage)
}

// MARK: - MovieDetailViewModel

@MainActor
@Observable
final class MovieDetailViewModel {

    // MARK: - Properties

    private(set) var state: MovieDetailViewState = .idle

    private let service: MovieDetailServicing

    // MARK: - Initialization

    init(service: MovieDetailServicing = MovieDetailService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadMovieDetail(id: Int) async {
        guard id > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到電影",
                    message: "電影 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading

        do {
            let detail = try await service.fetchMovieDetail(id: id)
            state = .loaded(MovieDetailItem(detail: detail))
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - MovieDetailItem

nonisolated struct MovieDetailItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let overview: String
    let posterURL: URL?
    let backdropURL: URL?
    let releaseDateText: String
    let runtimeText: String
    let scoreText: String
    let voteCountText: String
    let genresText: String
    let statusText: String
    let budgetText: String
    let revenueText: String
    let homepageURL: URL?
    let imdbURL: URL?
    let productionCompaniesText: String
    let spokenLanguagesText: String

    init(detail: MovieDetail) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = detail.tagline.isEmpty ? nil : detail.tagline
        self.overview = detail.overview.isEmpty ? "尚無簡介" : detail.overview
        self.posterURL = detail.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.backdropURL = detail.backdropPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w500)
        }
        self.releaseDateText = detail.releaseDate.isEmpty ? "尚未公布" : detail.releaseDate
        self.runtimeText = Self.formatRuntime(detail.runtime)
        self.scoreText = String(format: "%.1f", detail.voteAverage)
        self.voteCountText = "\(detail.voteCount) 人評分"
        self.genresText = Self.joinedNames(detail.genres.map(\.name), fallback: "未分類")
        self.statusText = detail.status.isEmpty ? "未知" : detail.status
        self.budgetText = Self.formatCurrency(detail.budget)
        self.revenueText = Self.formatCurrency(detail.revenue)
        self.homepageURL = Self.makeURL(from: detail.homepage)
        self.imdbURL = Self.makeIMDbURL(from: detail.imdbID)
        self.productionCompaniesText = Self.joinedNames(
            detail.productionCompanies.map(\.name),
            fallback: "尚無製作公司資訊"
        )
        self.spokenLanguagesText = Self.joinedNames(
            detail.spokenLanguages.map(\.name).filter { !$0.isEmpty },
            fallback: "尚無語言資訊"
        )
    }

    private static func formatRuntime(_ runtime: Int?) -> String {
        guard let runtime, runtime > 0 else { return "片長未知" }

        let hours = runtime / 60
        let minutes = runtime % 60

        if hours == 0 {
            return "\(minutes) 分鐘"
        }

        if minutes == 0 {
            return "\(hours) 小時"
        }

        return "\(hours) 小時 \(minutes) 分鐘"
    }

    private static func formatCurrency(_ value: Int) -> String {
        guard value > 0 else { return "未公開" }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    private static func joinedNames(_ names: [String], fallback: String) -> String {
        let visibleNames = names.filter { !$0.isEmpty }
        return visibleNames.isEmpty ? fallback : visibleNames.joined(separator: "、")
    }

    private static func makeURL(from string: String?) -> URL? {
        guard let string, !string.isEmpty else { return nil }
        return URL(string: string)
    }

    private static func makeIMDbURL(from imdbID: String?) -> URL? {
        guard let imdbID, !imdbID.isEmpty else { return nil }
        return URL(string: "https://www.imdb.com/title/\(imdbID)")
    }
}
