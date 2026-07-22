//
//  TVDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/7/1.
//

import Foundation
import Observation

// MARK: - State

nonisolated enum TVDetailViewState: Equatable {
    case idle
    case loading
    case loaded([TVDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - TVDetailViewModel

@MainActor
@Observable
final class TVDetailViewModel {

    // MARK: - Properties

    private(set) var state: TVDetailViewState = .idle
    private(set) var favoriteState: AccountMediaFavoriteState = .unavailable
    private(set) var ratingState: AccountMediaRatingState = .unavailable
    private(set) var ratingDefaultValue: Double = AccountMediaRatingValue.fallback

    private let service: TVDetailServicing
    private let accountMediaController: DetailAccountMediaStateController

    // MARK: - Initialization

    init(
        service: TVDetailServicing = TVDetailService(),
        sessionStore: SessionStoring = SessionStore(),
        accountService: AccountServiceProtocol = AccountService(),
        accountMediaService: MemberCenterServicing = MemberCenterService()
    ) {
        self.service = service
        self.accountMediaController = DetailAccountMediaStateController(
            sessionStore: sessionStore,
            accountService: accountService,
            accountMediaService: accountMediaService
        )
        accountMediaController.stateDidChange = { [weak self] in
            self?.syncAccountMediaState()
        }
        syncAccountMediaState()
    }

    // MARK: - Public Methods

    func loadTVDetail(seriesID: Int) async {
        guard seriesID > 0 else {
            state = .failed(
                ErrorMessage(
                    title: "找不到影集",
                    message: "影集 ID 不正確，請返回上一頁後再試。",
                    actionTitle: nil
                )
            )
            return
        }

        state = .loading
        accountMediaController.prepareForLoading()

        do {
            async let content = service.fetchTVDetailContent(seriesID: seriesID)
            await accountMediaController.loadAccountMediaState(
                sourceDescription: "TV series \(seriesID)"
            ) { [service] sessionID in
                try await service.fetchTVAccountStates(seriesID: seriesID, sessionId: sessionID)
            }
            let loadedContent = try await content
            accountMediaController.updateDefaultRating(
                fromPublicRating: loadedContent.detail.voteCount > 0
                    ? loadedContent.detail.voteAverage
                    : nil
            )
            state = .loaded(TVDetailSectionBuilder.makeSections(content: loadedContent))
        } catch {
            state = .failed(error.errorMessage)
            accountMediaController.markUnavailable()
        }
    }

    func toggleFavorite(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.toggleFavorite(
            mediaID: seriesID,
            mediaType: .tv,
            invalidMessage: ErrorMessage(title: "無法收藏", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    func submitRating(seriesID: Int, value: Double) async -> ErrorMessage? {
        await accountMediaController.submitRating(
            target: .tv(seriesID: seriesID),
            value: value,
            invalidMessage: ErrorMessage(title: "無法評分", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    func deleteRating(seriesID: Int) async -> ErrorMessage? {
        await accountMediaController.deleteRating(
            target: .tv(seriesID: seriesID),
            invalidMessage: ErrorMessage(title: "無法刪除評分", message: "影集 ID 不正確，請返回上一頁後再試。")
        )
    }

    // MARK: - Private Methods

    private func syncAccountMediaState() {
        favoriteState = accountMediaController.favoriteState
        ratingState = accountMediaController.ratingState
        ratingDefaultValue = accountMediaController.ratingDefaultValue
    }
}

// MARK: - TVDetailSectionItem

nonisolated enum TVDetailSectionItem: Sendable, Equatable {
    case overview(TVDetailOverviewSectionItem)
    case facts([TVDetailFactItem])
    case videos([TVDetailVideoItem])
    case attributes(TVDetailAttributeSectionItem)
    case cast([TVDetailCastItem])
    case seasons([TVDetailSeasonItem])
    case images([TVDetailImageItem])
    case recommendations([TVDetailRecommendationItem])

    var title: String? {
        switch self {
        case .overview:
            return nil

        case .facts:
            return "影集資訊"

        case .videos:
            return "預告與影片"

        case .attributes:
            return "類型與製作公司"

        case .cast:
            return "主要演員"

        case .seasons:
            return "季數"

        case .images:
            return "劇照"

        case .recommendations:
            return "推薦影集"
        }
    }

    var contentListConfiguration: DetailContentListConfiguration? {
        switch self {
        case .cast(let items):
            return DetailContentListConfiguration(
                title: title ?? "主要演員",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.profileURL,
                        title: item.name,
                        subtitle: item.characterText,
                        destination: .person(id: item.id)
                    )
                }
            )

        case .videos(let items):
            return DetailContentListConfiguration(
                title: title ?? "預告與影片",
                thumbnailStyle: .landscape,
                items: items.map { item in
                    let destination: DetailContentListDestination
                    if let videoKey = item.youtubeVideoKey {
                        destination = .youtube(videoKey: videoKey, title: item.title)
                    } else if let videoURL = item.videoURL {
                        destination = .webVideo(url: videoURL, title: item.title)
                    } else {
                        destination = .none
                    }

                    return DetailContentListItem(
                        id: item.id,
                        imageURL: item.thumbnailURL,
                        title: item.title,
                        subtitle: item.subtitle,
                        destination: destination
                    )
                }
            )

        case .images(let items):
            return DetailContentListConfiguration(
                title: title ?? "劇照",
                thumbnailStyle: .gallery,
                items: items.map { item in
                    DetailContentListItem(
                        id: item.id,
                        imageURL: item.imageURL,
                        title: item.title,
                        subtitle: item.resolutionText,
                        destination: .image(url: item.imageURL)
                    )
                }
            )

        case .recommendations(let items):
            return DetailContentListConfiguration(
                title: title ?? "推薦影集",
                thumbnailStyle: .portrait,
                items: items.map { item in
                    DetailContentListItem(
                        id: String(item.id),
                        imageURL: item.posterURL,
                        title: item.title,
                        subtitle: BaseDisplayTextFormatter.ratingText(item.scoreText),
                        destination: .tv(seriesID: item.id)
                    )
                }
            )

        case .overview, .facts, .attributes, .seasons:
            return nil
        }
    }
}

// MARK: - TVDetailSectionBuilder

nonisolated enum TVDetailSectionBuilder {

    static func makeSections(content: TVDetailContent) -> [TVDetailSectionItem] {
        let detailItem = TVDetailItem(detail: content.detail)
        var sections: [TVDetailSectionItem] = [
            .overview(
                TVDetailOverviewSectionItem(
                    hero: TVDetailHeroItem(detail: detailItem),
                    overview: detailItem.overview
                )
            )
        ]

        let facts = makeFacts(detail: detailItem)
        if !facts.isEmpty {
            sections.append(.facts(facts))
        }

        let videoItems = content.videos.results
            .filter { !$0.key.isEmpty }
            .sorted { lhs, rhs in
                videoPriority(lhs) < videoPriority(rhs)
            }
            .map(TVDetailVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(detail: content.detail) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .map(TVDetailCastItem.init(cast:))
        if !castItems.isEmpty {
            sections.append(.cast(Array(castItems)))
        }

        let seasonItems = content.detail.seasons
            .sorted { $0.seasonNumber < $1.seasonNumber }
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailSeasonItem.init(season:))
        if !seasonItems.isEmpty {
            sections.append(.seasons(Array(seasonItems)))
        }

        let imageItems = content.images.backdrops.enumerated().compactMap { index, image in
            TVDetailImageItem(image: image, index: index)
        }
        if !imageItems.isEmpty {
            sections.append(.images(imageItems))
        }

        let recommendationItems = content.recommendations.results
            .map(TVDetailRecommendationItem.init(recommendation:))
        if !recommendationItems.isEmpty {
            sections.append(.recommendations(Array(recommendationItems)))
        }

        return sections
    }

    private static func makeFacts(detail: TVDetailItem) -> [TVDetailFactItem] {
        [
            makeFact(title: "首播日", value: detail.firstAirDateText),
            makeFact(title: "最後播出", value: detail.lastAirDateText),
            makeFact(title: "季數", value: detail.seasonCountText),
            makeFact(title: "集數", value: detail.episodeCountText),
            makeFact(title: "單集長度", value: detail.episodeRunTimeText),
            makeFact(title: "狀態", value: detail.statusText),
            makeFact(title: "類型", value: detail.typeText)
        ].compactMap { $0 }
    }

    private static func makeFact(title: String, value: String?) -> TVDetailFactItem? {
        guard let value, !value.isEmpty else { return nil }
        return TVDetailFactItem(title: title, value: value)
    }

    private static func makeAttributes(detail: TVDetail) -> TVDetailAttributeSectionItem? {
        let genres = detail.genres.map(TVDetailAttributeItem.init(genre:))
        let productionCompanies = detail.productionCompanies
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailAttributeItem.init(productionCompany:))
        let networks = detail.networks
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailAttributeItem.init(network:))
        let section = TVDetailAttributeSectionItem(
            genres: genres,
            productionCompanies: Array(productionCompanies),
            networks: Array(networks)
        )

        return section.isEmpty ? nil : section
    }

    private static func videoPriority(_ video: TVVideo) -> Int {
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

// MARK: - TVDetailImageItem

nonisolated struct TVDetailImageItem: Sendable, Equatable, Identifiable {
    let id: String
    let title: String
    let resolutionText: String?
    let imageURL: URL

    init?(image: TVImage, index: Int) {
        guard let imageURL = APIConfig.tmdbImageURL(path: image.filePath, size: .w500) else {
            return nil
        }

        self.id = image.filePath
        self.title = "劇照 \(index + 1)"
        self.resolutionText = BaseDisplayTextFormatter.resolution(
            width: image.width,
            height: image.height
        )
        self.imageURL = imageURL
    }
}

// MARK: - TVDetailOverviewSectionItem

nonisolated struct TVDetailOverviewSectionItem: Sendable, Equatable {
    let hero: TVDetailHeroItem
    let overview: String?
}
