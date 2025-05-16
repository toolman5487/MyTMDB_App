//
//  ReviewView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/16.
//

import Foundation
import UIKit
import Combine

class MovieReviewTableView: UITableViewController {
    
    private let viewModel: MovieReviewViewModel
    init(movieId: Int) {
        self.viewModel = MovieReviewViewModel(movieId: movieId)
        super.init(style: .plain)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var reviews: [Review] = []
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.register(MovieReviewTableViewCell.self, forCellReuseIdentifier: "MovieReviewTableViewCell")
        bindViewModel()
        viewModel.fetchReviews()
    }

    private func bindViewModel() {
        viewModel.$reviews
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                self?.reviews = result
                print("Result:\(result)")
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return reviews.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MovieReviewTableViewCell", for: indexPath) as! MovieReviewTableViewCell
        cell.configure(with: reviews[indexPath.row])
        return cell
    }
}
