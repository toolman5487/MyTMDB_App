//
//  FavoritesRepository.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/27.
//

import Foundation
import Combine

final class FavoritesRepository {
    private let api: FavoriteServiceProtocol
    private let local: FavoritesLocalServiceProtocol

    init(api: FavoriteServiceProtocol = FavoriteService(),
         local: FavoritesLocalServiceProtocol = FavoritesLocalService()) {
        self.api = api
        self.local = local
    }

    func toggleFavorite(mediaType: String,
                        mediaId: Int,
                        title: String,
                        posterPath: String?, favorite: Bool, accountId: Int, sessionId: String) -> AnyPublisher<FavoriteResponse, Error> {
        return api.toggleFavorite(mediaType: mediaType, mediaId: mediaId, favorite: favorite, accountId: accountId, sessionId: sessionId)
            .handleEvents(receiveOutput: { [weak self] _ in
                if favorite {
                    self?.local.addFavorite(
                        id: mediaId,
                        title: title,
                        posterPath: posterPath,
                        mediaType: mediaType
                    )
                } else {
                    self?.local.removeFavorite(id: mediaId, mediaType: mediaType)
                }
            })
            .eraseToAnyPublisher()
    }
}
