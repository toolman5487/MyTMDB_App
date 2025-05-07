import Foundation
import UIKit
import Combine
import SnapKit
import SDWebImage

class SearchResultsView: UIViewController, UISearchResultsUpdating{
    
    private let viewModel = MultiSearchViewModel()
    private var results: [MultiSearchResult] = []
    private var cancellables = Set<AnyCancellable>()
    var didSelectMovie: ((Int) -> Void)?
    var didSelectTV: ((Int) -> Void)?
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var config = UIListContentConfiguration.subtitleCell()
        let result = results[indexPath.row]
        config.text = (result.mediaType == .movie ? result.title : result.name) ?? ""
        switch result.mediaType {
        case .movie:
            config.secondaryText = result.releaseDate
        case .tv:
            config.secondaryText = result.firstAirDate
        case .person:
            config.secondaryText = result.overview
        }
        
        if let path = result.posterPath ?? result.profilePath,
           let url = URL(string: "https://image.tmdb.org/t/p/w92\(path)") {
            config.image = UIImage(systemName: "photo")
            SDWebImageManager.shared.loadImage(
                with: url,
                options: [.highPriority],
                progress: nil
            ) { image, _, _, _, _, _ in
                DispatchQueue.main.async {
                    var updated = config
                    updated.image = image
                    cell.contentConfiguration = updated
                }
            }
        } else {
            config.image = UIImage(systemName: "photo")
        }
        config.imageProperties.maximumSize = CGSize(width: 60, height: 90)
        config.imageProperties.cornerRadius = 4
        
        cell.contentConfiguration = config
        cell.accessoryType = .disclosureIndicator
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let result = results[indexPath.row]
        guard let id = result.id else { return }
        switch result.mediaType {
        case .movie:
            didSelectMovie?(id)
        case .tv:
            print("tap tv id:", id)
            didSelectTV?(id)
        default:
            break
        }
    }
}
