//
//  FavoritesLocalService.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/27.
//

import Foundation
import CoreData

protocol FavoritesLocalServiceProtocol {
    func addFavorite(id: Int, title: String, posterPath: String?, mediaType: String)
    func removeFavorite(id: Int, mediaType: String)
    func isFavorited(id: Int, mediaType: String) -> Bool
    func makeFetchedResultsController() -> NSFetchedResultsController<FavoriteItem>
}

final class FavoritesLocalService: FavoritesLocalServiceProtocol {
    
    private let coreData = CoreDataManager.shared
    
    func addFavorite(id: Int, title: String, posterPath: String?, mediaType: String) {
        let context = coreData.newBackgroundContext()
        context.perform {
            let item = FavoriteItem(context: context)
            item.id = Int64(id)
            item.title = title
            item.posterPath = posterPath
            item.mediaType = mediaType
            item.addedAt = Date().timeIntervalSince1970.description
            self.coreData.saveContext(context)
            print("Added favorite locally: [\(mediaType)] \(title) (id: \(id))")
        }
    }

    func removeFavorite(id: Int, mediaType: String) {
        let context = coreData.newBackgroundContext()
        let request: NSFetchRequest<FavoriteItem> = FavoriteItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d AND mediaType == %@", id, mediaType)
        context.perform {
            if let item = try? context.fetch(request).first {
                context.delete(item)
                self.coreData.saveContext(context)
                print("Removed favorite locally: [\(mediaType)] id \(id)")
            }
        }
    }

    func isFavorited(id: Int, mediaType: String) -> Bool {
        let request: NSFetchRequest<FavoriteItem> = FavoriteItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d AND mediaType == %@", id, mediaType)
        let count = (try? coreData.viewContext.count(for: request)) ?? 0
        return count > 0
    }

    func makeFetchedResultsController() -> NSFetchedResultsController<FavoriteItem> {
        let request: NSFetchRequest<FavoriteItem> = FavoriteItem.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "addedAt", ascending: false)
        ]
        let fetchResults = NSFetchedResultsController(
            fetchRequest: request,
            managedObjectContext: coreData.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        try? fetchResults.performFetch()
        return fetchResults
    }
}
