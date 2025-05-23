//
//  TVReviewTableView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/17.
//

import Foundation
import UIKit
import Combine
import SnapKit

class TVReviewTableView: UITableViewController {
    
    private let viewModel: TVReviewViewModel
    init(tvId: Int){
        self.viewModel = TVReviewViewModel(tvId: tvId)
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var reviews:[Review] = []
    private var cancellables = Set <AnyCancellable>()
    
    private let tvEmptyLabel: UILabel = {
        let label = UILabel()
        label.text = "目前沒有評論"
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }()
    
    private func bindViewModel(){
        viewModel.$reviews
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.reviews = result
                self?.tableView.reloadData()
                
                if let table = self?.tableView {
                    if self?.reviews.isEmpty == true {
                        table.backgroundView = self?.tvEmptyLabel
                        table.separatorStyle = .none
                    } else {
                        table.backgroundView = nil
                        table.separatorStyle = .singleLine
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TVReviewTableViewCell", for: indexPath) as! TVReviewTableViewCell
        cell.tvConfig(with: reviews[indexPath.row])
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.register(TVReviewTableViewCell.self, forCellReuseIdentifier: "TVReviewTableViewCell")
        bindViewModel()
        viewModel.fetchReviews()
    }
}
