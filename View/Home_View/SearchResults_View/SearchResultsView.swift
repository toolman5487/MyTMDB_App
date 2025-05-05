//
//  SearchResultsView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/5.
//

import Foundation
import UIKit
import Combine

class SearchResultsView: UIViewController, UISearchResultsUpdating{
    
    private let tableView = UITableView()
    private var results: [MultiSearchResult] = []
    private let viewModel = MultiSearchViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        viewModel.search(query: text)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate   = self
    }
    
}

extension SearchResultsView: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        switch item.mediaType {
        case .movie:
            cell.textLabel?.text = item.title
        case .tv:
            cell.textLabel?.text = item.name
        case .person:
            cell.textLabel?.text = item.name
        }
        return cell
    }
    
    
}
