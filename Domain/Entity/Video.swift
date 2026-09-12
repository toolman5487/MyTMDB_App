//
//  Video.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Video

nonisolated struct Video: Sendable, Equatable, Identifiable {
    let id: String
    let name: String
    let key: String
    let site: String
    let type: String
    let isOfficial: Bool

    var isPlayable: Bool {
        !key.isEmpty
    }

    var isYouTube: Bool {
        site.lowercased() == "youtube"
    }
}
