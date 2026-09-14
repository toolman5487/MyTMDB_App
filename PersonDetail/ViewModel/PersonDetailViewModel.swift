//
//  PersonDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/2.
//

import Foundation

// MARK: - State

nonisolated enum PersonDetailViewState: Equatable {
    case idle
    case loading
    case loaded([PersonDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - PersonDetailCreditsListResult

nonisolated enum PersonDetailCreditsListResult: Equatable {
    case loaded(DetailContentListConfiguration)
    case failed(ErrorMessage)
}

// MARK: - PersonDetailViewModel

@MainActor
final class PersonDetailViewModel {

    // MARK: - Properties

    private(set) var state: PersonDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (PersonDetailViewState) -> Void)?
    private let loadPersonDetailUseCase: LoadPersonDetailUseCase
    private let loadPersonCreditsUseCase: LoadPersonCreditsUseCase

    // MARK: - Initialization

    init(
        loadPersonDetailUseCase: LoadPersonDetailUseCase,
        loadPersonCreditsUseCase: LoadPersonCreditsUseCase
    ) {
        self.loadPersonDetailUseCase = loadPersonDetailUseCase
        self.loadPersonCreditsUseCase = loadPersonCreditsUseCase
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (PersonDetailViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadPersonDetail(id: Int) async {
        state = .loading

        do {
            let content = try await loadPersonDetailUseCase(personID: id)
            guard !Task.isCancelled else { return }
            state = .loaded(PersonDetailSectionBuilder.makeSections(content: content))
        } catch let error as PersonDetailError {
            guard !Task.isCancelled else { return }
            state = .failed(Self.detailErrorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage)
        }
    }

    func loadCreditsList(
        id: Int,
        mediaType: PersonCreditMediaType
    ) async -> PersonDetailCreditsListResult {
        do {
            let credits = try await loadPersonCreditsUseCase(
                personID: id,
                mediaType: mediaType
            )

            let configuration = PersonDetailCreditsPresentationBuilder.makeContentListConfiguration(
                credits: credits,
                mediaType: mediaType
            )

            guard !configuration.items.isEmpty else {
                return .failed(
                    ErrorMessage(
                        title: "目前沒有作品",
                        message: "TMDB 尚未提供這位人物的\(configuration.title)資料。",
                        actionTitle: nil
                    )
                )
            }

            return .loaded(configuration)
        } catch let error as PersonDetailError {
            return .failed(Self.creditsErrorMessage(for: error))
        } catch {
            return .failed(error.errorMessage)
        }
    }

    // MARK: - Private Helpers

    private static func detailErrorMessage(for error: PersonDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier, .unsupportedCreditMediaType:
            return ErrorMessage(
                title: "找不到人物",
                message: "人物 ID 不正確，請返回上一頁後再試。",
                actionTitle: nil
            )
        }
    }

    private static func creditsErrorMessage(for error: PersonDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: "無法載入作品",
                message: "人物 ID 不正確，請返回上一頁後再試。",
                actionTitle: nil
            )

        case .unsupportedCreditMediaType:
            return ErrorMessage(
                title: "無法載入作品",
                message: "不支援這個作品類型。",
                actionTitle: nil
            )
        }
    }
}
