//
//  PersonDetailError.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - PersonDetailError

nonisolated enum PersonDetailError: Error, Equatable {
    case invalidIdentifier
    case unsupportedCreditMediaType
}
