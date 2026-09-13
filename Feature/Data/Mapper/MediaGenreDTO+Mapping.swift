//
//  MediaGenreDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - MediaGenreListDTO Mapping

extension MediaGenreListDTO {

    func mapped() -> [MediaGenre] {
        genres.map { $0.mapped() }
    }
}

// MARK: - MediaGenreDTO Mapping

extension MediaGenreDTO {

    func mapped() -> MediaGenre {
        MediaGenre(id: id, name: name)
    }
}
