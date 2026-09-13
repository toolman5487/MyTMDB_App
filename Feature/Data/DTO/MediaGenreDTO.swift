//
//  MediaGenreDTO.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaGenreListDTO

nonisolated struct MediaGenreListDTO: Decodable, Sendable, Equatable {
    let genres: [MediaGenreDTO]
}

// MARK: - MediaGenreDTO

nonisolated struct MediaGenreDTO: Decodable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
}
