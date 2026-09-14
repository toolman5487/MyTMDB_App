//
//  SDWebImageCacheStore.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation
import SDWebImage

// MARK: - SDWebImageCacheStore

nonisolated struct SDWebImageCacheStore: ImageCacheClearing {

    // MARK: - ImageCacheClearing

    func clearImageCache() async {
        SDImageCache.shared.clearMemory()
        await withCheckedContinuation { continuation in
            SDImageCache.shared.clearDisk {
                continuation.resume()
            }
        }
    }
}
