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

    private let service: TVDetailServicing
    private let sessionStore: SessionStoring
    private let accountService: AccountServiceProtocol
    private let accountMediaService: MainMemberCenterServicing
    private var favoriteSession: AccountMediaFavoriteSession?

    // MARK: - Initialization

    init(
        service: TVDetailServicing = TVDetailService(),
        sessionStore: SessionStoring = SessionStore(),
        accountService: AccountServiceProtocol = AccountService(),
        accountMediaService: MainMemberCenterServicing = MainMemberCenterService()
    ) {
        self.service = service
        self.sessionStore = sessionStore
        self.accountService = accountService
        self.accountMediaService = accountMediaService
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
        favoriteState = .unavailable
        favoriteSession = nil

        do {
            async let content = service.fetchTVDetailContent(seriesID: seriesID)
            let loadedFavoriteState = await loadFavoriteState(seriesID: seriesID)
            let loadedContent = try await content
            state = .loaded(TVDetailSectionBuilder.makeSections(content: loadedContent))
            favoriteState = loadedFavoriteState
        } catch {
            state = .failed(error.errorMessage)
            favoriteState = .unavailable
            favoriteSession = nil
        }
    }

    func toggleFavorite(seriesID: Int) async -> ErrorMessage? {
        guard seriesID > 0 else {
            return ErrorMessage(title: "無法收藏", message: "影集 ID 不正確，請返回上一頁後再試。")
        }

        switch favoriteState {
        case .requiresUserLogin:
            return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用收藏功能。")

        case .unavailable:
            return ErrorMessage(title: "暫時無法收藏", message: "目前無法取得收藏狀態，請稍後再試。")

        case .updating:
            return nil

        case .ready(let currentFavoriteStatus):
            guard let favoriteSession else {
                favoriteState = .requiresUserLogin
                return ErrorMessage(title: "需要登入", message: "請登入 TMDB 帳號後再使用收藏功能。")
            }

            let updatedFavoriteStatus = !currentFavoriteStatus
            favoriteState = .updating(isFavorite: updatedFavoriteStatus)

            do {
                let response = try await accountMediaService.updateFavorite(
                    accountId: favoriteSession.accountID,
                    sessionId: favoriteSession.sessionID,
                    request: MainMemberCenterFavoriteStatusRequest(
                        mediaType: .tv,
                        mediaID: seriesID,
                        favorite: updatedFavoriteStatus
                    )
                )

                guard response.success else {
                    favoriteState = .ready(isFavorite: currentFavoriteStatus)
                    return ErrorMessage(title: "收藏失敗", message: response.statusMessage)
                }

                favoriteState = .ready(isFavorite: updatedFavoriteStatus)
                return nil
            } catch {
                favoriteState = .ready(isFavorite: currentFavoriteStatus)
                return error.errorMessage
            }
        }
    }

    private func loadFavoriteState(seriesID: Int) async -> AccountMediaFavoriteState {
        guard case .user(let sessionID) = sessionStore.load() else {
            return .requiresUserLogin
        }

        async let account = accountService.fetchAccount(sessionId: sessionID)
        async let accountStates = service.fetchTVAccountStates(seriesID: seriesID, sessionId: sessionID)

        do {
            let loadedAccount = try await account
            let loadedAccountStates = try await accountStates
            favoriteSession = AccountMediaFavoriteSession(accountID: loadedAccount.id, sessionID: sessionID)
            return .ready(isFavorite: loadedAccountStates.favorite)
        } catch {
            favoriteSession = nil
            AppLogger.network.warning(
                "Failed to load TV favorite state for series \(seriesID, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
            return .unavailable
        }
    }
}

// MARK: - AccountMediaFavoriteSession

private nonisolated struct AccountMediaFavoriteSession: Sendable, Equatable {
    let accountID: Int
    let sessionID: String
}

// MARK: - TVDetailSectionItem

nonisolated enum TVDetailSectionItem: Sendable, Equatable {
    case overview(TVDetailOverviewSectionItem)
    case facts([TVDetailFactItem])
    case videos([TVDetailVideoItem])
    case attributes(TVDetailAttributeSectionItem)
    case cast([TVDetailCastItem])
    case seasons([TVDetailSeasonItem])
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

        case .recommendations:
            return "推薦影集"
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
            .prefix(DetailSectionPreviewLimit.itemCount)
            .map(TVDetailVideoItem.init(video:))
        if !videoItems.isEmpty {
            sections.append(.videos(Array(videoItems)))
        }

        if let attributes = makeAttributes(detail: content.detail) {
            sections.append(.attributes(attributes))
        }

        let castItems = content.aggregateCredits.cast
            .sorted { $0.order < $1.order }
            .prefix(DetailSectionPreviewLimit.itemCount)
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

        let recommendationItems = content.recommendations.results
            .prefix(DetailSectionPreviewLimit.itemCount)
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

// MARK: - TVDetailOverviewSectionItem

nonisolated struct TVDetailOverviewSectionItem: Sendable, Equatable {
    let hero: TVDetailHeroItem
    let overview: String?
}
