//
//  BaseDisplayTextFormatter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import UIKit

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

    static func overview(
        _ text: String?,
        localization: AppInterfaceLocalization
    ) -> String {
        self.text(
            text,
            fallback: localization.string(
                "common.fallback.no_overview",
                defaultValue: "No overview is available."
            )
        )
    }

    static func announcedText(
        _ text: String?,
        localization: AppInterfaceLocalization
    ) -> String {
        self.text(
            text,
            fallback: localization.string(
                "common.fallback.not_announced",
                defaultValue: "Not announced"
            )
        )
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

    static func ratingText(
        _ value: Double,
        localization: AppInterfaceLocalization
    ) -> String {
        ratingText(decimal(value), localization: localization)
    }

    static func ratingText(
        _ scoreText: String,
        localization: AppInterfaceLocalization
    ) -> String {
        localization.formatted(
            "common.rating.value_format",
            defaultValue: "Rating %@",
            scoreText
        )
    }

    static func ratingText(
        _ scoreText: String?,
        localization: AppInterfaceLocalization
    ) -> String? {
        nonEmptyText(scoreText).map {
            ratingText($0, localization: localization)
        }
    }

    static func ratingText(
        scoreText: String?,
        voteCountText: String?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let scoreText = nonEmptyText(scoreText) else {
            return nil
        }

        let ratingText: String = ratingText(scoreText, localization: localization)

        guard let voteCountText = nonEmptyText(voteCountText) else {
            return ratingText
        }

        return localization.formatted(
            "common.rating.with_vote_count_format",
            defaultValue: "%@ (%@)",
            ratingText,
            voteCountText
        )
    }

    static func userRatingText(
        _ value: Double,
        localization: AppInterfaceLocalization
    ) -> String {
        localization.formatted(
            "common.rating.user_value_format",
            defaultValue: "My Rating %@",
            decimal(value)
        )
    }

    static func unratedText(
        localization: AppInterfaceLocalization
    ) -> String {
        localization.string(
            "common.rating.not_rated",
            defaultValue: "Not rated"
        )
    }

    static func voteCount(_ value: Int) -> String? {
        value > 0 ? "\(value)" : nil
    }

    // MARK: - Runtime & Minutes

    static func runtime(
        minutes: Int?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let minutes, minutes > 0 else { return nil }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if hours == 0 {
            return localization.formatted(
                "common.duration.minutes_format",
                defaultValue: "%lld min",
                remainingMinutes
            )
        }

        if remainingMinutes == 0 {
            return localization.formatted(
                "common.duration.hours_format",
                defaultValue: "%lld hr",
                hours
            )
        }

        return localization.formatted(
            "common.duration.hours_minutes_format",
            defaultValue: "%1$lld hr %2$lld min",
            hours,
            remainingMinutes
        )
    }

    static func minutes(
        _ value: Int?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let value, value > 0 else { return nil }
        return localization.formatted(
            "common.duration.minutes_format",
            defaultValue: "%lld min",
            value
        )
    }

    static func firstMinutes(
        values: [Int],
        localization: AppInterfaceLocalization
    ) -> String? {
        minutes(values.first { $0 > 0 }, localization: localization)
    }

    static func firstRuntime(
        _ durations: [Duration],
        localization: AppInterfaceLocalization
    ) -> String? {
        firstMinutes(
            values: durations.map { Int($0.components.seconds / 60) },
            localization: localization
        )
    }

    // MARK: - Count

    enum CountUnit: Sendable {
        case episodes
        case seasons
        case votes
        case items
    }

    static func count(
        _ value: Int,
        unit: CountUnit,
        localization: AppInterfaceLocalization
    ) -> String? {
        value > 0 ? countText(value, unit: unit, localization: localization) : nil
    }

    static func countText(
        _ value: Int,
        unit: CountUnit,
        localization: AppInterfaceLocalization
    ) -> String {
        switch unit {
        case .episodes:
            return localization.formatted(
                "common.count.episodes_format",
                defaultValue: "%lld episodes",
                value
            )

        case .seasons:
            return localization.formatted(
                "common.count.seasons_format",
                defaultValue: "%lld seasons",
                value
            )

        case .votes:
            return localization.formatted(
                "common.count.votes_format",
                defaultValue: "%lld votes",
                value
            )

        case .items:
            return localization.formatted(
                "common.count.items_format",
                defaultValue: "%lld items",
                value
            )
        }
    }

    static func seasonNumberText(
        _ value: Int,
        localization: AppInterfaceLocalization
    ) -> String {
        localization.formatted(
            "common.season.number_format",
            defaultValue: "Season %lld",
            value
        )
    }

    static func episodeNumberText(
        _ value: Int,
        localization: AppInterfaceLocalization
    ) -> String {
        localization.formatted(
            "common.episode.number_format",
            defaultValue: "Episode %lld",
            value
        )
    }

    static func episodeTitle(
        _ name: String?,
        episodeNumber: Int,
        localization: AppInterfaceLocalization
    ) -> String {
        let title = nonEmptyText(name) ?? episodeNumberText(
            episodeNumber,
            localization: localization
        )
        return "\(episodeNumber). \(title)"
    }

    static func seasonEpisodeNumberText(
        seasonNumber: Int,
        episodeNumber: Int,
        localization: AppInterfaceLocalization
    ) -> String {
        localization.formatted(
            "common.season_episode.number_format",
            defaultValue: "S%1$lld E%2$lld",
            seasonNumber,
            episodeNumber
        )
    }

    // MARK: - Metadata

    static func metadata(_ values: [String?]) -> String? {
        let nonEmptyValues = nonEmptyTexts(values)
        return nonEmptyValues.isEmpty ? nil : nonEmptyValues.joined(separator: " · ")
    }

    // MARK: - Attributed Text

    @MainActor
    static func titleAttributedText(
        title: String?,
        trailingImage: UIImage? = nil,
        font: UIFont,
        textColor: UIColor = ThemeColor.highlight,
        trailingImageColor: UIColor? = nil
    ) -> NSAttributedString? {
        guard let title else { return nil }

        let attributedString = NSMutableAttributedString(
            string: title,
            attributes: [
                .font: font,
                .foregroundColor: textColor
            ]
        )

        guard let trailingImage else {
            return attributedString
        }

        attributedString.append(NSAttributedString(string: " "))

        let attachment = NSTextAttachment()
        attachment.image = trailingImage.withTintColor(
            trailingImageColor ?? textColor,
            renderingMode: .alwaysOriginal
        )
        attachment.bounds = CGRect(
            x: 0,
            y: (font.capHeight - trailingImage.size.height) / 2,
            width: trailingImage.size.width,
            height: trailingImage.size.height
        )
        attributedString.append(NSAttributedString(attachment: attachment))

        return attributedString
    }

    @MainActor
    static func titleAttributedText(
        _ title: String,
        font: UIFont,
        textColor: UIColor = ThemeColor.highlight
    ) -> NSAttributedString {
        titleAttributedText(
            title: title,
            font: font,
            textColor: textColor
        ) ?? NSAttributedString()
    }

    // MARK: - Currency

    static func currencyUSD(
        _ value: Int,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard value > 0 else { return nil }

        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = localization.language.locale
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

    static func isoDayText(from day: CalendarDay?) -> String? {
        guard let day else { return nil }
        return String(format: "%04d-%02d-%02d", day.year, day.month, day.day)
    }

    static func runtime(
        _ duration: Duration?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let duration else { return nil }
        return runtime(
            minutes: Int(duration.components.seconds / 60),
            localization: localization
        )
    }

    static func displayDate(
        from date: Date?,
        localization: AppInterfaceLocalization
    ) -> String? {
        guard let date else { return nil }

        return date.formatted(
            .dateTime
                .year()
                .month(.twoDigits)
                .day(.twoDigits)
                .locale(localization.language.locale)
        )
    }

    static func year(from dateText: String?) -> String? {
        guard let dateText = nonEmptyText(dateText),
              dateText.count >= 4 else {
            return nil
        }

        let yearText = String(dateText.prefix(4))
        return yearText.allSatisfy(\.isNumber) ? yearText : nil
    }
}
