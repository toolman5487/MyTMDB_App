//
//  CompanyDetailViewModel.swift
//  MyTMDB_App
//
//  Created by Claude on 2026/9/24.
//

import Foundation

// MARK: - CompanyDetailViewState

nonisolated enum CompanyDetailViewState: Equatable {
    case idle
    case loading
    case loaded([CompanyDetailSectionItem])
    case failed(ErrorMessage)
}

// MARK: - CompanyDetailViewModel

@MainActor
final class CompanyDetailViewModel {

    // MARK: - Properties

    private(set) var state: CompanyDetailViewState = .idle {
        didSet {
            guard oldValue != state else { return }
            onStateChange?(state)
        }
    }

    private var onStateChange: (@MainActor (CompanyDetailViewState) -> Void)?
    private let loadCompanyDetailUseCase: LoadCompanyDetailUseCase
    private let repository: CompanyDetailProviding
    private let localization: AppInterfaceLocalization
    private var content: CompanyDetailContent?

    // MARK: - Initialization

    init(
        loadCompanyDetailUseCase: LoadCompanyDetailUseCase,
        repository: CompanyDetailProviding,
        localization: AppInterfaceLocalization
    ) {
        self.loadCompanyDetailUseCase = loadCompanyDetailUseCase
        self.repository = repository
        self.localization = localization
    }

    // MARK: - Output Binding

    func bind(onStateChange: @escaping @MainActor (CompanyDetailViewState) -> Void) {
        self.onStateChange = onStateChange
        onStateChange(state)
    }

    // MARK: - Public Methods

    func loadInitialContent(companyID: Int) async {
        state = .loading
        content = nil

        do {
            let loadedContent = try await loadCompanyDetailUseCase(companyID: companyID)
            guard !Task.isCancelled else { return }
            content = loadedContent
            state = .loaded(CompanyDetailSectionBuilder.makeSections(
                content: loadedContent,
                localization: localization
            ))
        } catch let error as CompanyDetailError {
            guard !Task.isCancelled else { return }
            state = .failed(detailErrorMessage(for: error))
        } catch {
            guard !Task.isCancelled else { return }
            state = .failed(error.errorMessage(localization: localization))
        }
    }

    func contentList(
        companyID: Int,
        mediaKind: MediaKind
    ) -> CompanyDetailContentListResult? {
        guard let content else { return nil }

        guard let configuration = CompanyDetailContentListPresentationBuilder.makeContentListConfiguration(
            content: content,
            mediaKind: mediaKind,
            localization: localization
        ) else { return nil }

        let page: Page<MediaSummary> = mediaKind == .movie ? content.movies : content.tvShows
        let pageProvider: (any DetailContentListPageProviding)? = page.hasNextPage
            ? CompanyDetailContentListPageProvider(
                repository: repository,
                companyID: companyID,
                mediaKind: mediaKind,
                startingPage: page,
                localization: localization
            )
            : nil

        return CompanyDetailContentListResult(configuration: configuration, pageProvider: pageProvider)
    }

    // MARK: - Private Helpers

    private func detailErrorMessage(for error: CompanyDetailError) -> ErrorMessage {
        switch error {
        case .invalidIdentifier:
            return ErrorMessage(
                title: localization.string("company_detail.error.not_found.title", defaultValue: "Company Not Found"),
                message: localization.string(
                    "company_detail.error.invalid_id.message",
                    defaultValue: "The company ID is invalid. Go back and try again."
                ),
                actionTitle: nil
            )
        }
    }
}
