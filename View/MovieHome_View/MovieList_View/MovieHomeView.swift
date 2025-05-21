//
//  MovieView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/2.
//

import Foundation
import UIKit
import Combine
import SnapKit

class MovieHomeView: UIViewController {
    
    private let accountId: Int
    private let sessionId: String
    private let categories = ["現正熱映", "熱門", "經典好評", "即將上映"]
    private var selectedCategoryIndex = 0
    
    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var searchMovieResultsView = MovieSerachResultView(accountId: accountId, sessionId: sessionId)
    private lazy var searchController: UISearchController = {
        let search = UISearchController(searchResultsController: searchMovieResultsView)
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜尋電影"
        search.searchResultsUpdater = searchMovieResultsView
        return search
    }()

    private lazy var categoryCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .systemBackground
        collection.register(CategoryCell.self, forCellWithReuseIdentifier: "CategoryCell")
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()

    private lazy var tableView: UITableView = {
        let tableview = UITableView()
        tableview.register(MovieListCell.self, forCellReuseIdentifier: "MovieListCell")
        tableview.dataSource = self
        tableview.delegate = self
        tableview.rowHeight = 100
        return tableview
    }()
    

    private func configureCategoryStrip() {
        view.addSubview(categoryCollectionView)
        categoryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }

    private func configureTableView() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(categoryCollectionView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = searchController
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "電影"

        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    
    private func configureSearchAction() {
        searchMovieResultsView.didSelectMovie = { [weak self] movie in
            guard let self = self else { return }
            let detailVM = MovieDetailViewModel(movieId: movie.id)
            let detailVC = MovieDetailView(viewModel: detailVM,
                                           accountId: self.accountId,
                                           sessionId: self.sessionId)
            self.navigationController?.pushViewController(detailVC, animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchAction()
        configureCategoryStrip()
        configureTableView()
        setupNavigationBar()
    }
}

extension MovieHomeView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categories.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CategoryCell", for: indexPath) as! CategoryCell
        let text = categories[indexPath.item]
        cell.configure(text: text, selected: indexPath.item == selectedCategoryIndex)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCategoryIndex = indexPath.item
        collectionView.reloadData()
        tableView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = categories[indexPath.item]
        let width = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 32
        return CGSize(width: width, height: 32)
    }
}


extension MovieHomeView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedCategoryIndex {
        case 0: return nowPlayingItems.count
        case 1: return popularItems.count
        case 2: return topRatedItems.count
        case 3: return upcomingItems.count
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieListCell", for: indexPath) as! MovieListCell
        let movie: MovieSummary
        switch selectedCategoryIndex {
        case 0: movie = nowPlayingItems[indexPath.row]
        case 1: movie = popularItems[indexPath.row]
        case 2: movie = topRatedItems[indexPath.row]
        case 3: movie = upcomingItems[indexPath.row]
        default: fatalError("Invalid category")
        }
       
        return cell
    }
}
