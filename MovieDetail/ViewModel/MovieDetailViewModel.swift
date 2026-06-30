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
    case loaded([MovieDetailSectionItem])
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
            let content = try await service.fetchMovieDetailContent(id: id)
            state = .loaded(MovieDetailSectionBuilder.makeSections(content: content))
        } catch {
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - MovieDetailSectionItem

nonisolated enum MovieDetailSectionItem: Sendable, Equatable {
    case hero(MovieDetailHeroItem)
    case overview(String)
    case facts([MovieDetailFactItem])
    case cast([MovieDetailCastItem])
    case videos([MovieDetailVideoItem])
    case recommendations([MovieDetailRecommendationItem])

    var title: String? {
        switch self {
        case .hero:
            return nil

        case .overview:
            return "劇情簡介"

        case .facts:
            return "電影資訊"

        case .cast:
            return "主要演員"

        case .videos:
            return "預告與影片"

        case .recommendations:
            return "推薦電影"
        }
    }
}

// MARK: - MovieDetailSectionBuilder

nonisolated enum MovieDetailSectionBuilder {

    static func makeSections(content: MovieDetailContent) -> [MovieDetailSectionItem] {
        let detailItem = MovieDetailItem(detail: content.detail)
        var sections: [MovieDetailSectionItem] = [
            .hero(MovieDetailHeroItem(detail: detailItem)),
            .overview(detailItem.overview),
            .facts(makeFacts(detail: detailItem))
        ]

        let castItems = content.credits.cast
            .sorted { $0.order < $1.order }
            .prefix(12)
            .map(MovieDetailCastItem.init(cast:))
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let videoItems = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { lhs, rhs in
                videoPriority(lhs) < videoPriority(rhs)
            }
            .prefix(8)
            .map(MovieDetailVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        let recommendationItems = content.recommendations.results
            .prefix(12)
            .map(MovieDetailRecommendationItem.init(recommendation:))
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        return sections
    }

    private static func makeFacts(detail: MovieDetailItem) -> [MovieDetailFactItem] {
        [
            MovieDetailFactItem(title: "上映日", value: detail.releaseDateText),
            MovieDetailFactItem(title: "片長", value: detail.runtimeText),
            MovieDetailFactItem(title: "類型", value: detail.genresText),
            MovieDetailFactItem(title: "狀態", value: detail.statusText),
            MovieDetailFactItem(title: "預算", value: detail.budgetText),
            MovieDetailFactItem(title: "票房", value: detail.revenueText),
            MovieDetailFactItem(title: "語言", value: detail.spokenLanguagesText),
            MovieDetailFactItem(title: "製作", value: detail.productionCompaniesText)
        ]
    }

    private static func videoPriority(_ video: MovieVideo) -> Int {
        let typeRank: Int
        switch video.type.lowercased() {
        case "trailer":
            typeRank = 0

        case "teaser":
            typeRank = 1

        default:
            typeRank = 2
        }

        let siteRank = video.site.lowercased() == "youtube" ? 0 : 1
        let officialRank = video.official ? 0 : 1

        return (typeRank * 100) + (siteRank * 10) + officialRank
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

// MARK: - MovieDetailHeroItem

nonisolated struct MovieDetailHeroItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let originalTitle: String
    let tagline: String?
    let posterURL: URL?
    let backdropURL: URL?
    let scoreText: String
    let voteCountText: String
    let metadataText: String

    init(detail: MovieDetailItem) {
        self.id = detail.id
        self.title = detail.title
        self.originalTitle = detail.originalTitle
        self.tagline = detail.tagline
        self.posterURL = detail.posterURL
        self.backdropURL = detail.backdropURL
        self.scoreText = detail.scoreText
        self.voteCountText = detail.voteCountText
        self.metadataText = "\(detail.releaseDateText) · \(detail.runtimeText)"
    }
}

// MARK: - MovieDetailFactItem

nonisolated struct MovieDetailFactItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let value: String

    init(title: String, value: String) {
        self.id = title
        self.title = title
        self.value = value
    }
}

// MARK: - MovieDetailCastItem

nonisolated struct MovieDetailCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let characterText: String
    let profileURL: URL?

    init(cast: MovieCreditCast) {
        self.id = cast.id
        self.name = cast.name
        self.characterText = cast.character.isEmpty ? "角色未公開" : cast.character
        self.profileURL = cast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

// MARK: - MovieDetailVideoItem

nonisolated struct MovieDetailVideoItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailURL: URL?
    let videoURL: URL?

    init(video: MovieVideo) {
        self.id = video.id
        self.title = video.name
        self.subtitle = video.type.isEmpty ? video.site : "\(video.type) · \(video.site)"

        if video.site.lowercased() == "youtube" {
            self.thumbnailURL = URL(string: "https://img.youtube.com/vi/\(video.key)/hqdefault.jpg")
            self.videoURL = URL(string: "https://www.youtube.com/watch?v=\(video.key)")
        } else {
            self.thumbnailURL = nil
            self.videoURL = nil
        }
    }
}

// MARK: - MovieDetailRecommendationItem

nonisolated struct MovieDetailRecommendationItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let releaseDateText: String
    let scoreText: String
    let posterURL: URL?

    init(recommendation: MovieRecommendation) {
        self.id = recommendation.id
        self.title = recommendation.title
        self.releaseDateText = recommendation.releaseDate.isEmpty ? "尚未公布" : recommendation.releaseDate
        self.scoreText = String(format: "%.1f", recommendation.voteAverage)
        self.posterURL = recommendation.posterPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}
