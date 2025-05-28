//
//  MovieVideoModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/27.
//

import Foundation

struct MovieVideo: Codable {
  let id: String
  let iso639_1: String
  let iso3166_1: String
  let name: String
  let key: String
  let site: String
  let size: Int
  let type: String
  let official: Bool
  let publishedAt: String

  enum CodingKeys: String, CodingKey {
    case id
    case iso639_1 = "iso_639_1"
    case iso3166_1 = "iso_3166_1"
    case name, key, site, size, type, official
    case publishedAt = "published_at"
  }
}

struct MovieVideosResponse: Codable {
  let id: Int
  let results: [MovieVideo]
}
