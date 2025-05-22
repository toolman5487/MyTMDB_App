//
//  TVSearchResultView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/22.
//

import Foundation
import UIKit
import SnapKit
import Combine

class TVSearchResultView: UIViewController, UISearchResultsUpdating {

    private let viewModel = TVSearchViewModel()
    private var results: [TVShow] = []
    private var cancellables = Set<AnyCancellable>()

    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.dataSource = self
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        bindViewModel()
    }

    private func bindViewModel() {
        viewModel.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] shows in
                self?.results = shows
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text else { return }
        viewModel.search(query: query)
    }
}

extension TVSearchResultView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TVSearchCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "TVSearchCell")
        let tv = results[indexPath.row]
        cell.textLabel?.text = tv.name
        cell.detailTextLabel?.text = tv.firstAirDate
        return cell
    }
}
