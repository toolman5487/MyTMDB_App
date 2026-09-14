//
//  ImageCacheClearing.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - ImageCacheClearing

nonisolated protocol ImageCacheClearing: Sendable {
    func clearImageCache() async
}
