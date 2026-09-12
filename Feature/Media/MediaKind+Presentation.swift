//
//  MediaKind+Presentation.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - Display Text

extension MediaKind {

    var displayName: String {
        switch self {
        case .movie:
            return "電影"

        case .tv:
            return "影集"
        }
    }
}
