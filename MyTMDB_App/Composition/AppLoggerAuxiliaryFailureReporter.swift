//
//  AppLoggerAuxiliaryFailureReporter.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AppLoggerAuxiliaryFailureReporter

nonisolated struct AppLoggerAuxiliaryFailureReporter: AuxiliaryLoadFailureReporting {

    // MARK: - AuxiliaryLoadFailureReporting

    func reportAuxiliaryFailure(_ name: String, target: String, error: any Error) {
        AppLogger.network.warning(
            "Failed to load \(name, privacy: .public) for \(target, privacy: .public): \(error.localizedDescription, privacy: .public)"
        )
    }
}
