//
//  MovieGridPaginationTaskController.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/6.
//

import Foundation

// MARK: - MovieGridPaginationTaskController

@MainActor
final class MovieGridPaginationTaskController {

    // MARK: - Properties

    var isRunning: Bool {
        task != nil
    }

    private var task: Task<Void, Never>?
    private var generation = 0

    deinit {
        task?.cancel()
    }

    // MARK: - Methods

    func run(
        priority: TaskPriority = .utility,
        operation: @MainActor @escaping () async -> Void
    ) {
        guard task == nil else { return }

        generation += 1
        let currentGeneration = generation

        task = Task(priority: priority) { @MainActor [weak self] in
            guard let self else { return }

            defer {
                if generation == currentGeneration {
                    task = nil
                }
            }

            guard !Task.isCancelled, generation == currentGeneration else { return }
            await operation()
            guard !Task.isCancelled, generation == currentGeneration else { return }
        }
    }

    func cancel() {
        generation += 1
        task?.cancel()
        task = nil
    }
}
