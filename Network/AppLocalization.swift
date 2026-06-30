//
//  TMDBLocalization.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/30.
//

import Foundation

// MARK: - AppLocalization

nonisolated struct AppLocalization: Sendable, Equatable {
    let languageCode: String
    let regionCode: String
    let timeZoneIdentifier: String

    static let defaultUS = AppLocalization(
        languageCode: "en",
        regionCode: "US",
        timeZoneIdentifier: "America/New_York"
    )

    static var current: AppLocalization {
        make(
            locale: .autoupdatingCurrent,
            timeZone: .autoupdatingCurrent
        )
    }

    var languageParameter: String {
        "\(languageCode)-\(regionCode)"
    }

    var imageLanguageParameter: String {
        orderedImageLanguages.joined(separator: ",")
    }

    private var orderedImageLanguages: [String] {
        var values: [String] = []

        for value in [languageCode, "null", "en"] where !values.contains(value) {
            values.append(value)
        }

        return values
    }

    static func make(
        locale: Locale,
        timeZone: TimeZone
    ) -> AppLocalization {
        AppLocalization(
            languageCode: locale.language.languageCode?.identifier ?? defaultUS.languageCode,
            regionCode: locale.region?.identifier ?? defaultUS.regionCode,
            timeZoneIdentifier: timeZone.identifier.isEmpty ? defaultUS.timeZoneIdentifier : timeZone.identifier
        )
    }
}
