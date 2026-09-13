//
//  AccountMediaStateDTO+Mapping.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/9/13.
//

import Foundation

// MARK: - AccountMediaStatesDTO Mapping

extension AccountMediaStatesDTO {

    func mapped() -> AccountMediaState {
        AccountMediaState(
            id: id,
            isFavorite: favorite,
            rating: rated.value
        )
    }
}

// MARK: - AccountStatusResponseDTO Mapping

extension AccountStatusResponseDTO {

    func mapped() -> AccountActionResult {
        AccountActionResult(
            isSuccess: success,
            message: statusMessage
        )
    }
}
