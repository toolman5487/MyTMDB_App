//
//  AuthPage.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2026/6/28.
//

import UIKit

// MARK: - Auth Page

enum AuthPage: Int, CaseIterable {
    case login
    case guest
    case register

    func title(localization: AppInterfaceLocalization) -> String {
        switch self {
        case .login:
            return localization.string("common.action.sign_in", defaultValue: "Sign In")

        case .guest:
            return localization.string("common.account.guest", defaultValue: "Guest")

        case .register:
            return localization.string("common.action.register", defaultValue: "Register")
        }
    }
}

// MARK: - LoginEntryContext

enum LoginEntryContext {
    case root
    case inApp

    var pages: [AuthPage] {
        switch self {
        case .root:
            return AuthPage.allCases

        case .inApp:
            return [.login, .register]
        }
    }

    var showsCloseButton: Bool {
        self == .inApp
    }
}

// MARK: - AuthPageView

protocol AuthPageView: UIView {
    var page: AuthPage { get }
    func setInteractionEnabled(_ isEnabled: Bool)
}
