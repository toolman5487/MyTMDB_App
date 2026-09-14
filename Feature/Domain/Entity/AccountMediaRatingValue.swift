//
//  AccountMediaRatingValue.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaRatingValue

nonisolated enum AccountMediaRatingValue {
    static let minimum = 0.5
    static let maximum = 10.0
    static let step = 0.5
    static let fallback = 8.0

    static func normalized(_ value: Double) -> Double {
        let roundedValue = (value / step).rounded() * step
        return min(max(roundedValue, minimum), maximum)
    }

    static func defaultValue(fromPublicRating publicRating: Double?) -> Double {
        guard let publicRating, publicRating > 0 else {
            return fallback
        }

        return normalized(publicRating)
    }

    static func isValid(_ value: Double) -> Bool {
        let normalizedValue = normalized(value)
        return normalizedValue == value
            && (minimum...maximum).contains(value)
    }
}
