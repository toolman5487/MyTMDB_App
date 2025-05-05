import Foundation
import UIKit
import Combine
import SnapKit
import SDWebImage

class SearchResultsView: UIViewController, UISearchResultsUpdating{
    
    private var results: [MultiSearchResult] = []
    private let viewModel = MultiSearchViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        viewModel.search(query: text)
    }
    
    private func layout(){
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.results = items
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate   = self
        layout()
        bindViewModel()
    }
    
}

extension SearchResultsView: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        switch result.mediaType {
        case .movie:
            cell.textLabel?.text = result.title
            cell.detailTextLabel?.text = result.releaseDate
        case .tv:
            cell.textLabel?.text = result.name
            cell.detailTextLabel?.text = result.firstAirDate
        case .person:
            cell.textLabel?.text = result.name
        }
        return cell
    }
    
}
