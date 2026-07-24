//
//  DetailContentListModels.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/20.
//

import Foundation

// MARK: - DetailContentListConfiguration

nonisolated struct DetailContentListConfiguration: Sendable, Equatable {
    let title: String
    let thumbnailStyle: DetailContentListThumbnailStyle
    let items: [DetailContentListItem]
}

// MARK: - DetailContentListThumbnailStyle

nonisolated enum DetailContentListThumbnailStyle: Sendable, Equatable {
    case portrait
    case landscape
    case gallery
}

// MARK: - DetailContentListItem

nonisolated struct DetailContentListItem: Sendable, Equatable, Identifiable {
    let id: String
    let imageURL: URL?
    let title: String
    let subtitle: String?
    let destination: DetailContentListDestination
}

// MARK: - DetailContentListDestination

nonisolated enum DetailContentListDestination: Sendable, Equatable {
    case movie(id: Int)
    case tv(seriesID: Int)
    case episode(seriesID: Int, seasonNumber: Int, episodeNumber: Int)
    case person(id: Int)
    case youtube(videoKey: String, title: String?)
    case webVideo(url: URL, title: String?)
    case image(url: URL)
    case none
}
