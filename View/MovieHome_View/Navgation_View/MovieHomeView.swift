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
import Lottie

class MovieHomeView: UIViewController {
    
    private let accountId: Int
    private let sessionId: String
    private let categories = ["現正熱映", "熱門電影", "經典好評", "即將上映"]
    private var selectedCategoryIndex = 0
    private var nowPlayingItems: [MovieSummary] = []
    private var popularItems:   [MovieSummary] = []
    private var topRatedItems:  [MovieSummary] = []
    private var upcomingItems:  [MovieSummary] = []
    private var cancellables = Set<AnyCancellable>()
    
    private let loadingAnimationView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "Animation_popcorn")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.isHidden = true
        return animationView
    }()
    
    private let categoryLoadingView: LottieAnimationView = {
        let animationView = LottieAnimationView(name: "Animation_popcorn")
        animationView.loopMode = .loop
        animationView.contentMode = .scaleAspectFit
        animationView.isHidden = true
        return animationView
    }()
    
    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var viewModel = MovieListViewModel(
        nowPlayingService: NowPlayingService(),
        popularService: PopularMovieService(),
        topRatedService: TopRatedService(),
        upcomingService: UpcomingService()
    )
    
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
        return tableview
    }()
    

    private func layout() {
        view.addSubview(categoryCollectionView)
        categoryCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(categoryCollectionView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        view.addSubview(categoryLoadingView)
        categoryLoadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(300)
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
    
    private func updateCategoryLoadingState() {
        let currentItems: [MovieSummary]
        switch selectedCategoryIndex {
        case 0: currentItems = nowPlayingItems
        case 1: currentItems = popularItems
        case 2: currentItems = topRatedItems
        case 3: currentItems = upcomingItems
        default: currentItems = []
        }

        if currentItems.isEmpty {
            categoryLoadingView.isHidden = false
            categoryLoadingView.play()
        } else {
            categoryLoadingView.stop()
            categoryLoadingView.isHidden = true
        }
    }
    
    private func bindViewModel() {
        viewModel.$nowPlaying
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.nowPlayingItems = movies
                if self?.selectedCategoryIndex == 0 {
                    self?.tableView.reloadData()
                    self?.updateCategoryLoadingState()
                }
            }
            .store(in: &cancellables)

        viewModel.$popular
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.popularItems = movies
                if self?.selectedCategoryIndex == 1 {
                    self?.tableView.reloadData()
                    self?.updateCategoryLoadingState()
                }
            }
            .store(in: &cancellables)

        viewModel.$topRated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.topRatedItems = movies
                if self?.selectedCategoryIndex == 2 {
                    self?.tableView.reloadData()
                    self?.updateCategoryLoadingState()
                }
            }
            .store(in: &cancellables)

        viewModel.$upcoming
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movies in
                self?.upcomingItems = movies
                if self?.selectedCategoryIndex == 3 {
                    self?.tableView.reloadData()
                    self?.updateCategoryLoadingState()
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSearchAction()
        layout()
        setupNavigationBar()
        bindViewModel()
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
        updateCategoryLoadingState()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = categories[indexPath.item]
        let width = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 32
        return CGSize(width: width, height: 32)
    }
}


extension MovieHomeView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
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
        case 0:
            movie = nowPlayingItems[indexPath.row]
        case 1:
            movie = popularItems[indexPath.row]
        case 2:
            movie = topRatedItems[indexPath.row]
        case 3:
            movie = upcomingItems[indexPath.row]
        default: fatalError("Invalid category")
        }
        cell.movieCellConfigure(with: movie)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let movie: MovieSummary
        switch selectedCategoryIndex {
        case 0:
            movie = nowPlayingItems[indexPath.row]
        case 1:
            movie = popularItems[indexPath.row]
        case 2:
            movie = topRatedItems[indexPath.row]
        case 3:
            movie = upcomingItems[indexPath.row]
        default:
            fatalError("Invalid category")
        }
        let detailVM = MovieDetailViewModel(movieId: movie.id)
        let detailVC = MovieDetailView(viewModel: detailVM,
                                       accountId: self.accountId,
                                       sessionId: self.sessionId)
        navigationController?.pushViewController(detailVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
