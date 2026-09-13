//
//  TMDBPageResponse+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - TMDBPageResponse Mapping

extension TMDBPageResponse where Result == MediaSummaryDTO {

    func mapped() -> Page<MediaSummary> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map { $0.mapped() }
        )
    }
}
