//
//  AccountContentProviding.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountContentProviding

nonisolated protocol AccountContentProviding: Sendable {

    /// 本機快取的帳號資料；沒有快取時為 `nil`。呼叫端負責判斷是否為已登入狀態。
    func cachedProfile() -> AccountProfile?

    /// 取得帳號資料，並在成功時更新本機快取。
    func profile(sessionID: String) async throws -> AccountProfile

    func collection(
        destination: MemberCenterDestination,
        accountID: Int,
        sessionID: String,
        page: Int,
        posterFallbackLimit: Int
    ) async throws -> AccountCollection
}
