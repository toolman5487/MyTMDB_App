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

    var title: String {
        switch self {
        case .login: return "登入"
        case .guest: return "訪客"
        case .register: return "註冊"
        }
    }
}

// MARK: - AuthPageView

protocol AuthPageView: UIView {
    var page: AuthPage { get }
    func setInteractionEnabled(_ isEnabled: Bool)
}
