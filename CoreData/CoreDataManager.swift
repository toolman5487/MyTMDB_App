//
//  CoreDataManager.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/27.
//

import Foundation
import CoreData

final class CoreDataManager {
   
    static let shared = CoreDataManager()
    private let container: NSPersistentContainer
    
    private init(){
        container = NSPersistentContainer(name: "TMDBModel")
        container.loadPersistentStores { storeDescription, error in
                   if let error = error {
                       fatalError(error.localizedDescription)
                   }
               }
    }
    
    var viewContext: NSManagedObjectContext {
        container.viewContext
    }  // 主線程用於讀取Context

    func newBackgroundContext() -> NSManagedObjectContext {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    } // 背景 Context，用於寫入操作

    func saveContext(_ context: NSManagedObjectContext) {
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print(error.localizedDescription)
        }
    } // 將指定 context 的更動儲存到底層存放區
    
}
