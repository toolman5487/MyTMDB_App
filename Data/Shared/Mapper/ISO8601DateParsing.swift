//
//  ISO8601DateParsing.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - ISO8601DateParsing

nonisolated enum ISO8601DateParsing {

    static func date(from rawValue: String?) -> Date? {
        guard let rawValue, !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        let fractionalSecondsFormatter = ISO8601DateFormatter()
        fractionalSecondsFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return fractionalSecondsFormatter.date(from: rawValue)
            ?? ISO8601DateFormatter().date(from: rawValue)
    }
}
