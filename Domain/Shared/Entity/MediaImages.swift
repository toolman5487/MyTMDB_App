//
//  MediaImages.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - MediaImages

nonisolated struct MediaImages: Sendable, Equatable {
    let backdrops: [MediaImage]
    let posters: [MediaImage]
    let logos: [MediaImage]

    static let empty = MediaImages(backdrops: [], posters: [], logos: [])
}

// MARK: - MediaImage

nonisolated struct MediaImage: Sendable, Equatable {
    let filePath: String
    let width: Int
    let height: Int
}
