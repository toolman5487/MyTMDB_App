//
//  MainMemberCenterViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/10.
//

import Foundation
import Observation

// MARK: - MainMemberCenterViewModel

@MainActor
@Observable
final class MainMemberCenterViewModel {

    // MARK: - Properties

    private(set) var state: MainMemberCenterViewState = .idle

    private let session: AuthSession
    private let service: MainMemberCenterServicing

    // MARK: - Initialization

    init(
        session: AuthSession,
        service: MainMemberCenterServicing = MainMemberCenterService()
    ) {
        self.session = session
        self.service = service
    }

    // MARK: - Public Methods

    func loadContent() async {
        guard case .user(let sessionId) = session else {
            state = .failed(Self.unavailableSessionMessage(for: session))
            return
        }

        state = .loading

        do {
            let snapshot = try await service.fetchContent(sessionId: sessionId)
            guard !Task.isCancelled else { return }
            let content = MainMemberCenterPresentationBuilder.makeContent(from: snapshot)
            state = .loaded(content)
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    // MARK: - Private Methods

    private static func unavailableSessionMessage(for session: AuthSession) -> ErrorMessage {
        switch session {
        case .loggedOut:
            return ErrorMessage(
                title: "尚未登入",
                message: "請先使用 TMDB 帳號登入後再查看會員中心。",
                systemImageName: "person.crop.circle.badge.exclamationmark"
            )

        case .guest:
            return ErrorMessage(
                title: "訪客無法使用會員中心",
                message: "請登入 TMDB 帳號以同步個人資料、收藏、待看與評分內容。",
                systemImageName: "person.crop.circle.badge.xmark"
            )

        case .user:
            return ErrorMessage(
                title: "無法載入會員中心",
                message: "請稍後再重新整理。",
                actionTitle: "重試"
            )
        }
    }
}
