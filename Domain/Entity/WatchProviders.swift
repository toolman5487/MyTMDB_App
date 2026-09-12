//
//  WatchProviders.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/12.
//

import Foundation

// MARK: - WatchProviders

nonisolated struct WatchProviders: Sendable, Equatable {
    let countries: [String: WatchProviderCountry]

    static let empty = WatchProviders(countries: [:])
}

// MARK: - WatchProviderCountry

nonisolated struct WatchProviderCountry: Sendable, Equatable {
    let link: String
    let flatrate: [WatchProvider]
    let rent: [WatchProvider]
    let buy: [WatchProvider]
    let free: [WatchProvider]
    let ads: [WatchProvider]
}

// MARK: - WatchProvider

nonisolated struct WatchProvider: Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let logoPath: String?
    let displayPriority: Int
}
