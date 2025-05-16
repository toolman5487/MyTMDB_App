//
//  CreditsResponseModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/14.
//

import Foundation
struct MovieCreditsResponse: Codable {
  let id: Int
  let cast: [CastMember]
}

struct CastMember: Codable {
  let id: Int
  let name: String
  let character: String?
  let profilePath: String?
  
  enum CodingKeys: String, CodingKey {
    case id, name, character
    case profilePath = "profile_path"
  }
}
