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
    let languageRegionCode: String
    let regionCode: String
    let timeZoneIdentifier: String

    static let defaultUS = AppLocalization(
        languageCode: "en",
        languageRegionCode: "en-US",
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
        languageRegionCode
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
        let languageLocale = preferredLanguageLocale(fallback: locale)
        let languageCode = languageLocale.language.languageCode?.identifier
            ?? locale.language.languageCode?.identifier
            ?? defaultUS.languageCode
        let regionCode = locale.region?.identifier
            ?? languageLocale.region?.identifier
            ?? defaultUS.regionCode

        return AppLocalization(
            languageCode: languageCode,
            languageRegionCode: languageRegionCode(
                languageCode: languageCode,
                languageLocale: languageLocale,
                fallbackRegionCode: regionCode
            ),
            regionCode: regionCode,
            timeZoneIdentifier: timeZone.identifier.isEmpty ? defaultUS.timeZoneIdentifier : timeZone.identifier
        )
    }

    private static func preferredLanguageLocale(fallback locale: Locale) -> Locale {
        guard let identifier = Locale.preferredLanguages.first else {
            return locale
        }

        return Locale(identifier: identifier)
    }

    private static func languageRegionCode(
        languageCode: String,
        languageLocale: Locale,
        fallbackRegionCode: String
    ) -> String {
        if languageCode == "zh" {
            return chineseLanguageRegionCode(
                languageLocale: languageLocale,
                fallbackRegionCode: fallbackRegionCode
            )
        }

        let regionCode = languageLocale.region?.identifier ?? fallbackRegionCode
        return "\(languageCode)-\(regionCode)"
    }

    private static func chineseLanguageRegionCode(
        languageLocale: Locale,
        fallbackRegionCode: String
    ) -> String {
        let identifier = languageLocale.identifier.lowercased()
        let regionCode = (languageLocale.region?.identifier ?? fallbackRegionCode).uppercased()

        if identifier.contains("hant") || ["TW", "HK", "MO"].contains(regionCode) {
            return "zh-TW"
        }

        return "zh-CN"
    }
}
