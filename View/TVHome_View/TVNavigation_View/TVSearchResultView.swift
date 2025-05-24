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

    private let accountId: Int
    private let sessionId: String
    private let viewModel = TVSearchViewModel()
    private var results: [TVShow] = []
    var didSelectTV: ((TVShow) -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.dataSource = self
        tableview.delegate = self
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

extension TVSearchResultView: UITableViewDataSource, UITableViewDelegate{
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tv = results[indexPath.row]
        didSelectTV?(tv)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
