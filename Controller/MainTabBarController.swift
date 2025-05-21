//
//  MainTabBarController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController {
    
    private let accountId: Int
    private let sessionId: String
    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let homeVC = HomeView()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "首頁",
                                          image: UIImage(systemName: "person.fill"),
                                          tag: 0)
        let movieVC = MovieHomeView(accountId: accountId, sessionId: sessionId)
        let movieNav = UINavigationController(rootViewController: movieVC)
        movieNav.tabBarItem = UITabBarItem(title: "電影",
                                           image: UIImage(systemName: "movieclapper.fill"),
                                           tag: 1)
        let tvVC = TVHomeView()
        let tvNav = UINavigationController(rootViewController: tvVC)
        tvNav.tabBarItem = UITabBarItem(title: "劇集",
                                           image: UIImage(systemName: "appletv.fill"),
                                           tag: 2)
        viewControllers = [homeNav, movieNav, tvNav]
    }
}
