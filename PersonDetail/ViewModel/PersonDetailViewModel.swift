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
    private let localization: AppInterfaceLocalization

    // MARK: - Initialization

    init(
        loadPersonDetailUseCase: LoadPersonDetailUseCase,
        loadPersonCreditsUseCase: LoadPersonCreditsUseCase,
        localization: AppInterfaceLocalization
    ) {
        self.loadPersonDetailUseCase = loadPersonDetailUseCase
        self.loadPersonCreditsUseCase = loadPersonCreditsUseCase
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (PersonDetailViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent(personID: Int) async {
        state = .loading

        do {
            let content = try await loadPersonDetailUseCase(personID: personID)
            guard !Task.isCancelled else { return }
            state = .loaded(PersonDetailSectionBuilder.makeSections(
                content: content,
                localization: localization
            ))
        } catch let error as PersonDetailError {
            guard !Task.isCancelled else { return }
            state = .failed(detailErrorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func loadCreditsList(
        personID: Int,
        mediaType: PersonCreditMediaType
    ) async -> PersonDetailCreditsListResult {
        do {
            let credits = try await loadPersonCreditsUseCase(
                personID: personID,
                mediaType: mediaType
            )

            let configuration = PersonDetailCreditsPresentationBuilder.makeContentListConfiguration(
                credits: credits,
                mediaType: mediaType,
                localization: localization
            )

            guard !configuration.items.isEmpty else {
                return .failed(
                    ErrorMessage(
                        title: localization.string(
                            "person_detail.credits.empty.title",
                            defaultValue: "No Credits Yet"
                        ),
                        message: emptyCreditsMessage(for: mediaType),
                        actionTitle: nil
                    )
                )
            }

            return .loaded(configuration)
        } catch let error as PersonDetailError {
            return .failed(creditsErrorMessage(for: error))
        } catch {
            return .failed(error.errorMessage(localization: localization))
        }
    }

    // MARK: - Private Helpers

    private var invalidPersonIDMessage: String {
        localization.string(
            "person_detail.error.invalid_id.message",
            defaultValue: "The person ID is invalid. Go back and try again."
        )
    }

    private var creditsLoadFailedTitle: String {
        localization.string(
            "person_detail.credits.error.title",
            defaultValue: "Unable to Load Credits"
        )
    }

    private func emptyCreditsMessage(for mediaType: PersonCreditMediaType) -> String {
        switch mediaType {
        case .movie:
            return localization.string(
                "person_detail.credits.empty.movie.message",
                defaultValue: "TMDB doesn't have movie credits for this person yet."
            )

        case .tv:
            return localization.string(
                "person_detail.credits.empty.tv.message",
                defaultValue: "TMDB doesn't have TV credits for this person yet."
            )

        case .unknown:
            return localization.string(
                "person_detail.credits.empty.other.message",
                defaultValue: "TMDB doesn't have credits for this person yet."
            )
        }
    }

    private func detailErrorMessage(for error: PersonDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier, .unsupportedCreditMediaType:
            return ErrorMessage(
                title: localization.string(
                    "person_detail.error.not_found.title",
                    defaultValue: "Person Not Found"
                ),
                message: invalidPersonIDMessage,
                actionTitle: nil
            )
        }
    }

    private func creditsErrorMessage(for error: PersonDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: creditsLoadFailedTitle,
                message: invalidPersonIDMessage,
                actionTitle: nil
            )

        case .unsupportedCreditMediaType:
            return ErrorMessage(
                title: creditsLoadFailedTitle,
                message: localization.string(
                    "person_detail.credits.error.unsupported_type.message",
                    defaultValue: "This credit type isn't supported."
                ),
                actionTitle: nil
            )
        }
    }
}
