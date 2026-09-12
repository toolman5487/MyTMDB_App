//
//  CalendarDayParsing.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - CalendarDayParsing

nonisolated enum CalendarDayParsing {

    static func calendarDay(from rawValue: String?) -> CalendarDay? {
        guard let rawValue else { return nil }

        let components = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "-", omittingEmptySubsequences: false)
        guard components.count == 3,
              let year = Int(components[0]),
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return nil
        }

        return CalendarDay(year: year, month: month, day: day)
    }
}
