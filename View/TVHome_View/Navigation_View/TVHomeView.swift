//
//  TVHomeView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import UIKit
import SnapKit

class TVHomeView:UIViewController{
    
    private lazy var tvSearchController: UISearchController = {
        let resultsVC = TVSearchResultView()
        let search = UISearchController(searchResultsController: resultsVC)
        search.searchResultsUpdater = resultsVC
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜尋電視節目"
        return search
    }()
    
    private func setupTVNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = tvSearchController
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "電視節目"
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTVNavigationBar()
    }
}
