//
//  ReviewDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - ReviewsPageDTO Mapping

extension ReviewsPageDTO {

    func mapped() -> Page<Review> {
        Page(
            number: page,
            totalPages: totalPages,
            totalResults: totalResults,
            items: results.map { $0.mapped() }
        )
    }
}

// MARK: - ReviewDTO Mapping

extension ReviewDTO {

    func mapped() -> Review {
        Review(
            id: id,
            authorName: Self.resolvedAuthorName(
                name: authorDetails.name,
                username: authorDetails.username,
                author: author
            ),
            rating: authorDetails.rating,
            content: content.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: ISO8601DateParsing.date(from: createdAt),
            updatedAt: ISO8601DateParsing.date(from: updatedAt),
            avatarPath: authorDetails.avatarPath
        )
    }

    private static func resolvedAuthorName(
        name: String,
        username: String,
        author: String
    ) -> String {
        let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !displayName.isEmpty {
            return displayName
        }

        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedUsername.isEmpty {
            return trimmedUsername
        }

        return author.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
