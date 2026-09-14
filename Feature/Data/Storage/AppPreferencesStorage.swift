//
//  AppPreferencesStorage.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation
import Synchronization

// MARK: - AppPreferencesStorage

nonisolated final class AppPreferencesStorage: Sendable {

    // MARK: - Properties

    static let standard = AppPreferencesStorage()

    private let lock = Mutex(())
    private let suiteName: String?

    // MARK: - Initialization

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    // MARK: - Public Methods

    func performLocked<Result>(_ work: (UserDefaults) -> Result) -> Result {
        lock.withLock { _ in
            let preferencesStore = suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
            return work(preferencesStore)
        }
    }
}
