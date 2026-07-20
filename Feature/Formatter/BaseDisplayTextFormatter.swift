//
//  BaseDisplayTextFormatter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import Foundation

// MARK: - BaseDisplayTextFormatter

nonisolated enum BaseDisplayTextFormatter {

    static func nonEmptyText(_ text: String?) -> String? {
        guard let text else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    static func score(_ value: Double, voteCount: Int) -> String? {
        guard voteCount > 0 else { return nil }
        return String(format: "%.1f", value)
    }

    static func voteCount(_ value: Int) -> String? {
        value > 0 ? "\(value)" : nil
    }

    static func runtime(minutes: Int?) -> String? {
        guard let minutes, minutes > 0 else { return nil }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return "\(remainingMinutes) 分鐘"
        }

        if remainingMinutes == 0 {
            return "\(hours) 小時"
        }

        return "\(hours) 小時 \(remainingMinutes) 分鐘"
    }

    static func minutes(_ value: Int?) -> String? {
        guard let value, value > 0 else { return nil }
        return "\(value) 分鐘"
    }

    static func firstMinutes(values: [Int]) -> String? {
        minutes(values.first { $0 > 0 })
    }

    static func count(_ value: Int, unit: String) -> String? {
        value > 0 ? "\(value) \(unit)" : nil
    }

    static func currencyUSD(_ value: Int) -> String? {
        guard value > 0 else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    static func resolution(width: Int, height: Int) -> String? {
        width > 0 && height > 0 ? "\(width) × \(height)" : nil
    }
}
