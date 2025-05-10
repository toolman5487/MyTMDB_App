//
//  FavoriteTVResponse.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/9.
//

import Foundation

struct FavoriteTVResponseModel: Decodable {
    let page: Int
    let results: [TVDetailModel]
    let totalPages: Int
    let totalResults: Int
    
    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages   = "total_pages"
        case totalResults = "total_results"
    }
}

