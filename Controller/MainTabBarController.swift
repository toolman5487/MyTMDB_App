//
//  MainTabBarController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit

class MainTabBarController:UITabBarController{
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let homeVC = HomeView()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "首頁",
                                          image: UIImage(systemName: "person.fill"),
                                          tag: 0)
        let movieVC = MovieView()
        let movieNav = UINavigationController(rootViewController: movieVC)
        movieNav.tabBarItem = UITabBarItem(title: "電影",
                                           image: UIImage(systemName: "movieclapper.fill"),
                                           tag: 1)
        viewControllers = [homeNav, movieNav]
    }
}
