//
//  SearchHistoryStore.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/29.
//

import Foundation

// MARK: - SearchHistoryStoring

nonisolated protocol SearchHistoryStoring {
    func load(scope: SearchHistoryScope?, limit: Int) -> [SearchHistoryEntry]
    func add(keyword: String, scope: SearchHistoryScope)
    func remove(id: UUID)
    func move(id: UUID, to destinationIndex: Int, scope: SearchHistoryScope)
    func clear(scope: SearchHistoryScope?)
}

// MARK: - SearchHistoryStore

final class SearchHistoryStore: SearchHistoryStoring {

    // MARK: - Properties

    private let defaults: UserDefaults
    private let storageKey: String
    private let maxEntriesPerScope: Int
    private let lock = NSLock()

    // MARK: - Initialization

    init(
        defaults: UserDefaults = .standard,
        storageKey: String = "SearchHistory.v1",
        maxEntriesPerScope: Int = 15
    ) {
        self.defaults = defaults
        self.storageKey = storageKey
        self.maxEntriesPerScope = maxEntriesPerScope
    }

    // MARK: - SearchHistoryStoring

    func load(scope: SearchHistoryScope?, limit: Int) -> [SearchHistoryEntry] {
        guard limit > 0 else { return [] }

        return lock.performLocked {
            let entries = sortedEntries(loadEntries())
            let scopedEntries = entries.filter { entry in
                scope.map { entry.scope == $0 } ?? true
            }
            return Array(scopedEntries.prefix(limit))
        }
    }

    func add(keyword: String, scope: SearchHistoryScope) {
        let trimmedKeyword = SearchHistoryEntry.trimmedKeyword(keyword)
        guard !trimmedKeyword.isEmpty else { return }

        lock.performLocked {
            let normalizedKeyword = SearchHistoryEntry.normalizedKeyword(trimmedKeyword)
            var entries = loadEntries()
            let matchesDuplicate: (SearchHistoryEntry) -> Bool = { entry in
                entry.scope == scope &&
                    SearchHistoryEntry.normalizedKeyword(entry.keyword) == normalizedKeyword
            }
            let existingEntry = sortedEntries(entries.filter(matchesDuplicate)).first

            entries.removeAll(where: matchesDuplicate)

            if let existingEntry {
                entries.append(
                    existingEntry.updating(
                        keyword: trimmedKeyword,
                        createdAt: Date()
                    )
                )
            } else {
                entries.append(
                    SearchHistoryEntry(
                        keyword: trimmedKeyword,
                        scope: scope,
                        createdAt: Date(),
                        sortIndex: 0
                    )
                )
            }

            saveEntries(normalizedEntries(entries))
        }
    }

    func remove(id: UUID) {
        lock.performLocked {
            var entries = loadEntries()
            entries.removeAll { $0.id == id }
            saveEntries(normalizedEntries(entries))
        }
    }

    func move(id: UUID, to destinationIndex: Int, scope: SearchHistoryScope) {
        lock.performLocked {
            let entries = loadEntries()
            var scopedEntries = sortedEntries(entries.filter { $0.scope == scope })

            guard let sourceIndex = scopedEntries.firstIndex(where: { $0.id == id }) else {
                return
            }

            let movedEntry = scopedEntries.remove(at: sourceIndex)
            let boundedDestinationIndex = min(max(0, destinationIndex), scopedEntries.count)
            scopedEntries.insert(movedEntry, at: boundedDestinationIndex)

            let reorderedScopedEntries = scopedEntries.enumerated().map { index, entry in
                entry.updatingSortIndex(index)
            }
            let otherEntries = entries.filter { $0.scope != scope }

            saveEntries(normalizedEntries(otherEntries + reorderedScopedEntries))
        }
    }

    func clear(scope: SearchHistoryScope?) {
        lock.performLocked {
            guard let scope else {
                defaults.removeObject(forKey: storageKey)
                return
            }

            let entries = loadEntries().filter { $0.scope != scope }
            saveEntries(normalizedEntries(entries))
        }
    }

    // MARK: - Private Methods

    private func loadEntries() -> [SearchHistoryEntry] {
        guard let data = defaults.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([SearchHistoryEntry].self, from: data)) ?? []
    }

    private func saveEntries(_ entries: [SearchHistoryEntry]) {
        guard !entries.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return
        }

        guard let data = try? JSONEncoder().encode(sortedEntries(entries)) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func normalizedEntries(_ entries: [SearchHistoryEntry]) -> [SearchHistoryEntry] {
        let limit = max(0, maxEntriesPerScope)

        return SearchHistoryScope.allCases.flatMap { scope in
            sortedEntries(entries.filter { $0.scope == scope })
                .prefix(limit)
                .enumerated()
                .map { index, entry in
                    entry.updatingSortIndex(index)
                }
        }
    }

    private func sortedEntries(_ entries: [SearchHistoryEntry]) -> [SearchHistoryEntry] {
        entries.sorted { lhs, rhs in
            if lhs.sortIndex != rhs.sortIndex {
                return lhs.sortIndex < rhs.sortIndex
            }

            if lhs.createdAt != rhs.createdAt {
                return lhs.createdAt > rhs.createdAt
            }

            return lhs.keyword < rhs.keyword
        }
    }
}

// MARK: - NSLock Convenience

private extension NSLock {

    func performLocked<Result>(_ work: () -> Result) -> Result {
        lock()
        defer { unlock() }
        return work()
    }
}
