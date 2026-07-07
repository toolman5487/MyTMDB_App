//
//  SeasonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation
import Observation

// MARK: - SeasonDetailViewState

nonisolated enum SeasonDetailViewState: Equatable {
    case idle
    case loading
    case loaded(SeasonDetailViewContent)
    case failed(ErrorMessage)
}

// MARK: - SeasonDetailViewContent

nonisolated struct SeasonDetailViewContent: Sendable, Equatable {
    let sections: [SeasonDetailSectionItem]
    let navigationTitle: String
}

// MARK: - SeasonDetailViewModel

@MainActor
@Observable
final class SeasonDetailViewModel {

    // MARK: - Properties

    private(set) var state: SeasonDetailViewState = .idle

    private let service: SeasonDetailServicing

    // MARK: - Initialization

    init(service: SeasonDetailServicing = SeasonDetailService()) {
        self.service = service
    }

    // MARK: - Public Methods

    func loadSeasonDetail(
        seriesID: Int,
        seasonNumber: Int
    ) async {
        guard seriesID > 0, seasonNumber >= 0 else {
            state = .failed(
                ErrorMessage(
                    title: "資料錯誤",
                    message: "缺少有效的劇集或季數資訊。"
                )
            )
            return
        }

        state = .loading

        do {
            let content = try await service.fetchSeasonDetailContent(
                seriesID: seriesID,
                seasonNumber: seasonNumber
            )
            guard !Task.isCancelled else { return }

            state = .loaded(SeasonDetailSectionBuilder.makeContent(content: content))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }
}

// MARK: - SeasonDetailSectionItem

nonisolated enum SeasonDetailSectionItem: Sendable, Equatable {
    case overview(SeasonDetailOverviewSectionItem)
    case facts([SeasonDetailFactItem])
    case episodes([SeasonEpisodeItem])
    case videos([SeasonVideoItem])
    case cast([SeasonCastItem])
    case crew([SeasonCrewItem])
    case images(SeasonImageGalleryItem)
    case watchProviders([SeasonWatchProviderItem])
    case accountState(SeasonAccountStateItem)

    var title: String? {
        switch self {
        case .overview:
            return nil
        case .facts:
            return "資訊"
        case .episodes:
            return "集數"
        case .videos:
            return "影片"
        case .cast:
            return "演員"
        case .crew:
            return "製作團隊"
        case .images:
            return "圖片"
        case .watchProviders:
            return "觀看平台"
        case .accountState:
            return "個人狀態"
        }
    }
}

// MARK: - SeasonDetailOverviewSectionItem

nonisolated struct SeasonDetailOverviewSectionItem: Sendable, Equatable {
    let hero: SeasonDetailItem
    let overview: String?
}

// MARK: - SeasonDetailSectionBuilder

nonisolated enum SeasonDetailSectionBuilder {

    private static let previewItemLimit = 12

    static func makeContent(content: SeasonDetailContent) -> SeasonDetailViewContent {
        let detail = SeasonDetailItem(detail: content.detail)

        return SeasonDetailViewContent(
            sections: makeSections(content: content, detail: detail),
            navigationTitle: detail.title
        )
    }

    private static func makeSections(
        content: SeasonDetailContent,
        detail: SeasonDetailItem
    ) -> [SeasonDetailSectionItem] {
        var sections: [SeasonDetailSectionItem] = [
            .overview(
                SeasonDetailOverviewSectionItem(
                    hero: detail,
                    overview: content.detail.overview.isEmpty ? nil : content.detail.overview
                )
            )
        ]

        let facts = makeFacts(detail: content.detail, detailItem: detail)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let episodes = content.detail.episodes
            .sorted { $0.episodeNumber < $1.episodeNumber }
            .map(SeasonEpisodeItem.init(episode:))
        if !episodes.isEmpty {
            sections.append(.episodes(episodes))
        }

        let videos = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { videoPriority($0) < videoPriority($1) }
            .prefix(previewItemLimit)
            .map(SeasonVideoItem.init(video:))
        if !videos.isEmpty {
            sections.append(.videos(Array(videos)))
        }

        let cast = makeCastItems(content: content)
        if !cast.isEmpty {
            sections.append(.cast(cast))
        }

        let crew = makeCrewItems(content: content)
        if !crew.isEmpty {
            sections.append(.crew(crew))
        }

        if let images = makeImageGalleryItem(images: content.images) {
            sections.append(.images(images))
        }

        let watchProviders = makeWatchProviderItems(response: content.watchProviders)
        if !watchProviders.isEmpty {
            sections.append(.watchProviders(watchProviders))
        }

        if case .rated = content.accountStates.rated {
            sections.append(.accountState(SeasonAccountStateItem(accountStates: content.accountStates)))
        }

        return sections
    }

    private static func makeFacts(
        detail: SeasonDetail,
        detailItem: SeasonDetailItem
    ) -> [SeasonDetailFactItem] {
        [
            makeFact(title: "季數", value: detailItem.seasonNumberText),
            makeFact(title: "集數", value: detailItem.episodeCountText),
            makeFact(title: "首播日期", value: detail.airDate.isEmpty ? nil : detail.airDate),
            makeFact(title: "評分", value: detail.voteAverage > 0 ? detailItem.scoreText : nil)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> SeasonDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return SeasonDetailFactItem(title: title, value: value)
    }

    private static func makeCastItems(content: SeasonDetailContent) -> [SeasonCastItem] {
        let aggregateCast = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .prefix(previewItemLimit)
            .map(SeasonCastItem.init(aggregateCast:))

        if !aggregateCast.isEmpty {
            return Array(aggregateCast)
        }

        return Array(
            content.credits.cast
                .sorted { $0.order < $1.order }
                .prefix(previewItemLimit)
                .map(SeasonCastItem.init(creditCast:))
        )
    }

    private static func makeCrewItems(content: SeasonDetailContent) -> [SeasonCrewItem] {
        let aggregateCrew = content.aggregateCredits.crew
            .sorted { lhs, rhs in
                if lhs.department != rhs.department {
                    return lhs.department < rhs.department
                }

                return lhs.name < rhs.name
            }
            .prefix(previewItemLimit)
            .map(SeasonCrewItem.init(aggregateCrew:))

        if !aggregateCrew.isEmpty {
            return Array(aggregateCrew)
        }

        return Array(
            content.credits.crew
                .sorted { lhs, rhs in
                    if lhs.department != rhs.department {
                        return lhs.department < rhs.department
                    }

                    return lhs.name < rhs.name
                }
                .prefix(previewItemLimit)
                .map(SeasonCrewItem.init(creditCrew:))
        )
    }

    private static func makeImageGalleryItem(images: TVImagesResponse) -> SeasonImageGalleryItem? {
        let posters = images.posters
            .filter { !$0.filePath.isEmpty }
            .prefix(previewItemLimit)
            .map(SeasonImageItem.init(image:))
        let backdrops = images.backdrops
            .filter { !$0.filePath.isEmpty }
            .prefix(previewItemLimit)
            .map(SeasonImageItem.init(image:))
        let logos = images.logos
            .filter { !$0.filePath.isEmpty }
            .prefix(previewItemLimit)
            .map(SeasonImageItem.init(image:))

        let item = SeasonImageGalleryItem(
            posters: Array(posters),
            backdrops: Array(backdrops),
            logos: Array(logos)
        )

        return item.isEmpty ? nil : item
    }

    private static func makeWatchProviderItems(response: TVWatchProvidersResponse) -> [SeasonWatchProviderItem] {
        response.results
            .sorted { $0.key < $1.key }
            .flatMap { countryCode, country in
                country.flatrate.map { provider in
                    SeasonWatchProviderItem(
                        countryCode: countryCode,
                        provider: provider,
                        category: "串流",
                        link: country.link
                    )
                }
            }
            .prefix(previewItemLimit)
            .map { $0 }
    }

    private static func videoPriority(_ video: TVVideo) -> Int {
        switch video.type.lowercased() {
        case "trailer":
            return 0
        case "teaser":
            return 1
        case "clip":
            return 2
        default:
            return 3
        }
    }
}

// MARK: - Presentation Items

nonisolated struct SeasonVideoItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let thumbnailURL: URL?
    let youtubeVideoKey: String?
    let videoURL: URL?

    init(video: TVVideo) {
        self.id = video.id
        self.title = video.name
        self.subtitle = video.type.isEmpty ? video.site : "\(video.type) · \(video.site)"

        if video.site.lowercased() == "youtube", !video.key.isEmpty {
            self.youtubeVideoKey = video.key
            self.thumbnailURL = URL(string: "https://img.youtube.com/vi/\(video.key)/hqdefault.jpg")
            self.videoURL = URL(string: "https://www.youtube.com/watch?v=\(video.key)")
        } else {
            self.youtubeVideoKey = nil
            self.thumbnailURL = nil
            self.videoURL = nil
        }
    }
}

nonisolated struct SeasonCastItem: Sendable, Equatable, Identifiable {
    let id: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCast: TVAggregateCreditCast) {
        self.id = aggregateCast.id
        self.title = aggregateCast.name
        self.subtitle = aggregateCast.roles.first?.character
        self.profileURL = aggregateCast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCast: SeasonCreditCast) {
        self.id = creditCast.id
        self.title = creditCast.name
        self.subtitle = creditCast.character.isEmpty ? nil : creditCast.character
        self.profileURL = creditCast.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonCrewItem: Sendable, Equatable, Identifiable {
    let id: String
    let personID: Int
    let title: String
    let subtitle: String?
    let profileURL: URL?

    init(aggregateCrew: TVAggregateCreditCrew) {
        self.id = "\(aggregateCrew.id)-\(aggregateCrew.department)"
        self.personID = aggregateCrew.id
        self.title = aggregateCrew.name
        self.subtitle = aggregateCrew.jobs.first?.job ?? aggregateCrew.department
        self.profileURL = aggregateCrew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }

    init(creditCrew: SeasonCreditCrew) {
        self.id = creditCrew.creditID
        self.personID = creditCrew.id
        self.title = creditCrew.name
        self.subtitle = creditCrew.job.isEmpty ? creditCrew.department : creditCrew.job
        self.profileURL = creditCrew.profilePath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonImageGalleryItem: Sendable, Equatable {
    let posters: [SeasonImageItem]
    let backdrops: [SeasonImageItem]
    let logos: [SeasonImageItem]

    var isEmpty: Bool {
        posters.isEmpty && backdrops.isEmpty && logos.isEmpty
    }
}

nonisolated struct SeasonImageItem: Sendable, Equatable, Identifiable {
    var id: String {
        filePath
    }

    let filePath: String
    let imageURL: URL?
    let aspectRatio: Double

    init(image: TVImage) {
        self.filePath = image.filePath
        self.imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500)
        self.aspectRatio = image.aspectRatio
    }
}

nonisolated struct SeasonWatchProviderItem: Sendable, Equatable, Identifiable {
    var id: String {
        "\(countryCode)-\(category)-\(providerID)"
    }

    let countryCode: String
    let providerID: Int
    let title: String
    let category: String
    let linkURL: URL?
    let logoURL: URL?

    init(
        countryCode: String,
        provider: TVWatchProvider,
        category: String,
        link: String
    ) {
        self.countryCode = countryCode
        self.providerID = provider.id
        self.title = provider.name
        self.category = category
        self.linkURL = URL(string: link)
        self.logoURL = provider.logoPath.flatMap {
            APIConfig.tmdbImageURL(path: $0, size: .w185)
        }
    }
}

nonisolated struct SeasonAccountStateItem: Sendable, Equatable {
    let ratingText: String

    init(accountStates: SeasonAccountStatesResponse) {
        switch accountStates.rated {
        case .unrated:
            self.ratingText = "尚未評分"

        case .rated(let value):
            self.ratingText = String(format: "%.1f", value)
        }
    }
}
