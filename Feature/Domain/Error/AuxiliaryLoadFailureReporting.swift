//
//  AuxiliaryLoadFailureReporting.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/14.
//

import Foundation

// MARK: - AuxiliaryLoadFailureReporting

nonisolated protocol AuxiliaryLoadFailureReporting: Sendable {
    func reportAuxiliaryFailure(_ name: String, target: String, error: any Error)
}
