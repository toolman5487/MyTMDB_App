//
//  TVHomeView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/20.
//

import Foundation
import UIKit
import SnapKit
import Combine

class TVHomeView:UIViewController{
    
    private let accountId: Int
    private let sessionId: String
    private let tvCategories = ["今日播出", "正在播出", "熱門節目", "評分最高"]
    private var selectedTVCategoryIndex = 0
    private var airingTodayItems:[TVListShow] = []
    private var onTheAirItems:[TVListShow] = []
    private var popularTVItems:[TVListShow] = []
    private var topRatedTVItems:[TVListShow] = []
    private var cancellables = Set<AnyCancellable>()
    
    init(accountId: Int, sessionId: String) {
        self.accountId = accountId
        self.sessionId = sessionId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var viewModel = TVListViewModel(
        airingTodayService: AiringTodayService(),
        onTheAirService: OnTheAirService(),
        popularService: PopularTVService(),
        topRatedService: TopRatedTVService()
    )
    
    private lazy var tvSearchController: UISearchController = {
        let resultsVC = TVSearchResultView()
        let search = UISearchController(searchResultsController: resultsVC)
        search.searchResultsUpdater = resultsVC
        search.obscuresBackgroundDuringPresentation = false
        search.searchBar.placeholder = "搜尋電視節目"
        return search
    }()
    
    private lazy var categoryTVCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .systemBackground
        collection.register(TVCategoryCell.self, forCellWithReuseIdentifier: "TVCategoryCell")
        collection.dataSource = self
        collection.delegate = self
        return collection
    }()
    
    private lazy var tvTableView:UITableView = {
        let tableview = UITableView()
        tableview.dataSource = self
        tableview.delegate = self
        tableview.register(TVListCell.self, forCellReuseIdentifier: "TVListCell")
        return tableview
    }()
    
    private func setupTVNavigationBar() {
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.searchController = tvSearchController
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "電視節目"
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }
    
    private func layout() {
        view.addSubview(categoryTVCollectionView)
        categoryTVCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        view.addSubview(tvTableView)
        tvTableView.snp.makeConstraints { make in
            make.top.equalTo(categoryTVCollectionView.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func bindTVListViewModel() {
        viewModel.$airingToday
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tv in
                self?.airingTodayItems = tv
                if self?.selectedTVCategoryIndex == 0 {
                    self?.tvTableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$onTheAir
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tv in
                self?.onTheAirItems = tv
                if self?.selectedTVCategoryIndex == 1 {
                    self?.tvTableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$popular
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tv in
                self?.popularTVItems = tv
                if self?.selectedTVCategoryIndex == 2 {
                    self?.tvTableView.reloadData()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$topRated
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tv in
                self?.topRatedTVItems = tv
                if self?.selectedTVCategoryIndex == 3{
                    self?.tvTableView.reloadData()
                }
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTVNavigationBar()
        layout()
        bindTVListViewModel()
        viewModel.fetchAllTVLists()
    }
}

extension TVHomeView: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tvCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TVCategoryCell", for: indexPath) as! TVCategoryCell
        let text = tvCategories[indexPath.item]
        cell.configure(text: text, selected: indexPath.item == selectedTVCategoryIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = tvCategories[indexPath.item]
        let width = text.size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .medium)]).width + 32
        
        return CGSize(width: width, height: 32)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTVCategoryIndex = indexPath.item
        collectionView.reloadData()
        tvTableView.reloadData()
    }
}

extension TVHomeView:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch selectedTVCategoryIndex {
        case 0: return viewModel.airingToday.count
        case 1: return viewModel.onTheAir.count
        case 2: return viewModel.popular.count
        case 3: return viewModel.topRated.count
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TVListCell", for: indexPath) as! TVListCell
        let shows: TVListShow
        switch selectedTVCategoryIndex {
        case 0:
            shows = airingTodayItems[indexPath.row]
        case 1:
            shows = onTheAirItems[indexPath.row]
        case 2:
            shows = popularTVItems[indexPath.row]
        case 3:
            shows = topRatedTVItems[indexPath.row]
        default:
            fatalError("Invalid category")
        }
        cell.tvCellConfigure(with: shows)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 140
    }
    
}
