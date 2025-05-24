//
//  MovieSerachResultView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import UIKit
import Combine
import SnapKit

class MovieSerachResultView: UIViewController, UISearchResultsUpdating {
    
    private let accountId: Int
    private let sessionId: String
    private let viewModel = MovieSearchViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var movies: [Movie] = []
    var didSelectMovie: ((Movie) -> Void)?

    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupTableView()
        bindViewModel()
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.$movies
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.movies = movies
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let query = searchController.searchBar.text, !query.isEmpty else {
            movies = []
            tableView.reloadData()
            return
        }
        viewModel.searchMovies(query: query)
    }

}

extension MovieSerachResultView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return movies.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieCell") ??
            UITableViewCell(style: .subtitle, reuseIdentifier: "MovieCell")
        let movie = movies[indexPath.row]
        cell.textLabel?.text = movie.title
        cell.detailTextLabel?.text = movie.releaseDate
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let movie = movies[indexPath.row]
        didSelectMovie?(movie)
    }
}
