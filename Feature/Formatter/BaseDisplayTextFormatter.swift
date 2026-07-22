//
//  BaseDisplayTextFormatter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import Foundation

// MARK: - BaseDisplayTextFormatter

nonisolated enum BaseDisplayTextFormatter {

    // MARK: - Text Sanitization

    static func nonEmptyText(_ text: String?) -> String? {
        guard let text else { return nil }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedText.isEmpty ? nil : trimmedText
    }

    static func nonEmptyTexts(_ values: [String?]) -> [String] {
        values.compactMap(nonEmptyText)
    }

    static func firstNonEmptyText(_ values: [String?]) -> String? {
        values.lazy.compactMap(nonEmptyText).first
    }

    static func text(_ text: String?, fallback: String) -> String {
        nonEmptyText(text) ?? fallback
    }

    static func overview(_ text: String?) -> String {
        self.text(text, fallback: "目前沒有簡介。")
    }

    static func announcedText(_ text: String?) -> String {
        self.text(text, fallback: "尚未公布")
    }

    // MARK: - Score & Vote Count

    static func score(_ value: Double, voteCount: Int) -> String? {
        guard voteCount > 0 else { return nil }
        return decimal(value)
    }

    static func score(_ rating: Double?) -> String? {
        positiveDecimal(rating)
    }

    static func decimal(_ value: Double) -> String {
        String(format: "%.1f", value)
    }

    static func positiveDecimal(_ value: Double) -> String? {
        positiveDecimal(Optional(value))
    }

    static func positiveDecimal(_ value: Double?) -> String? {
        guard let value, value > 0 else { return nil }
        return decimal(value)
    }

    static func ratingText(_ value: Double) -> String {
        ratingText(decimal(value))
    }

    static func ratingText(_ scoreText: String) -> String {
        prefixedText("評分", value: scoreText)
    }

    static func ratingText(_ scoreText: String?) -> String? {
        nonEmptyText(scoreText).map(ratingText)
    }

    static func ratingText(
        scoreText: String?,
        voteCountText: String?
    ) -> String? {
        guard let scoreText = nonEmptyText(scoreText),
              let voteCountText = nonEmptyText(voteCountText) else {
            return nil
        }

        return "\(ratingText(scoreText)) (\(voteCountText))"
    }

    static func userRatingText(_ value: Double) -> String {
        prefixedText("我的評分", value: decimal(value))
    }

    static var unratedText: String {
        "尚未評分"
    }

    static func voteCount(_ value: Int) -> String? {
        value > 0 ? "\(value)" : nil
    }

    // MARK: - Runtime & Minutes

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

    // MARK: - Count

    static func count(_ value: Int, unit: String) -> String? {
        value > 0 ? countText(value, unit: unit) : nil
    }

    static func countText(_ value: Int, unit: String) -> String {
        "\(value) \(unit)"
    }

    static func seasonNumberText(_ value: Int) -> String {
        "第 \(value) 季"
    }

    static func episodeNumberText(_ value: Int) -> String {
        "第 \(value) 集"
    }

    static func seasonEpisodeNumberText(
        seasonNumber: Int,
        episodeNumber: Int
    ) -> String {
        "\(seasonNumberText(seasonNumber))\(episodeNumberText(episodeNumber))"
    }

    // MARK: - Metadata

    static func metadata(_ values: [String?]) -> String? {
        let nonEmptyValues = nonEmptyTexts(values)
        return nonEmptyValues.isEmpty ? nil : nonEmptyValues.joined(separator: " · ")
    }

    // MARK: - Private Helpers

    private static func prefixedText(_ prefix: String, value: String) -> String {
        "\(prefix) \(value)"
    }

    // MARK: - Currency

    static func currencyUSD(_ value: Int) -> String? {
        guard value > 0 else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0

        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }

    // MARK: - Resolution

    static func resolution(width: Int, height: Int) -> String? {
        width > 0 && height > 0 ? "\(width) × \(height)" : nil
    }

    static func resolutionText(width: Int, height: Int) -> String {
        resolution(width: width, height: height) ?? ""
    }

    // MARK: - Date

    static func iso8601Date(from rawValue: String?) -> Date? {
        guard let rawValue = nonEmptyText(rawValue) else { return nil }

        let fractionalSecondsFormatter = ISO8601DateFormatter()
        fractionalSecondsFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return fractionalSecondsFormatter.date(from: rawValue)
            ?? ISO8601DateFormatter().date(from: rawValue)
    }

    static func iso8601Date(from rawValue: String) -> Date? {
        iso8601Date(from: Optional(rawValue))
    }

    static func iso8601DisplayDate(from rawValue: String?) -> String? {
        guard let date = iso8601Date(from: rawValue) else { return nil }

        return date.formatted(
            .dateTime
                .year()
                .month(.twoDigits)
                .day(.twoDigits)
        )
    }
}
