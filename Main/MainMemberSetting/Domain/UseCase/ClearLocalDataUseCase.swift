//
//  ClearLocalDataUseCase.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - ClearLocalDataUseCase

nonisolated protocol ClearLocalDataUseCase: Sendable {
    func callAsFunction() async
}

// MARK: - DefaultClearLocalDataUseCase

nonisolated struct DefaultClearLocalDataUseCase: ClearLocalDataUseCase {

    // MARK: - Properties

    private let logout: LogoutUseCase
    private let searchHistory: SearchHistoryProviding
    private let imageCache: ImageCacheClearing

    // MARK: - Initialization

    init(
        logout: LogoutUseCase,
        searchHistory: SearchHistoryProviding,
        imageCache: ImageCacheClearing
    ) {
        self.logout = logout
        self.searchHistory = searchHistory
        self.imageCache = imageCache
    }

    // MARK: - ClearLocalDataUseCase

    func callAsFunction() async {
        logout()
        searchHistory.clear(scope: nil)
        await imageCache.clearImageCache()
    }
}
