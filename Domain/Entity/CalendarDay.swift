//
//  CalendarDay.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - CalendarDay

nonisolated struct CalendarDay: Sendable, Equatable, Comparable, Hashable {
    let year: Int
    let month: Int
    let day: Int

    static func < (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }
}
