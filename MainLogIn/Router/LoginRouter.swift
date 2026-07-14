//
//  LoginRouter.swift
//  MyTMDB_App
//
//  Created by Codex on 2026/7/14.
//

import UIKit

// MARK: - LoginRouting

@MainActor
protocol LoginRouting: AnyObject {
    func openSignup(url: URL)
}

// MARK: - LoginRouter

@MainActor
final class LoginRouter: BaseRouter, LoginRouting {

    func openSignup(url: URL) {
        openSafari(url)
    }
}
