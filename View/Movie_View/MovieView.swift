//
//  MovieView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import Combine

class MovieView:UIViewController{
    
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "探索"
        definesPresentationContext = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()

    }
}
