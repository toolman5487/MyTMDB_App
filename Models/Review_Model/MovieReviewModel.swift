//
//  MovieReviewModel.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/16.
//

import Foundation

struct ReviewResponse: Codable {
    let id: Int
    let page: Int
    let results: [Review]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case id, page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}


struct AuthorDetails: Codable {
    let name: String
    let username: String
    let avatarPath: String?
    let rating: Double?
    
    enum CodingKeys: String, CodingKey {
        case name, username
        case avatarPath = "avatar_path"
        case rating
    }
}

struct Review: Codable {
    let author: String
    let authorDetails: AuthorDetails
    let content: String
    let id: String
    let url: String
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case author
        case authorDetails = "author_details"
        case content, id, url
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
