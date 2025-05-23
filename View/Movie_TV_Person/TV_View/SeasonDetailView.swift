//
//  SeasonDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/12.
//

import UIKit
import Combine
import SDWebImage
import SnapKit
import SnapKit

class SeasonDetailView: UITableViewController {
    private let viewModel: SeasonDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    private var episodes: [EpisodeModel] = []
    private let seasonNumber: Int
    
    init(tvId: Int, seasonNumber: Int) {
        self.viewModel = SeasonDetailViewModel(tvId: tvId, seasonNumber: seasonNumber)
        self.seasonNumber = seasonNumber
        super.init(style: .insetGrouped)
        navigationItem.largeTitleDisplayMode = .never
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func bindViewModel() {
        viewModel.$episodes
            .receive(on: DispatchQueue.main)
            .sink { [weak self] eps in
                self?.episodes = eps
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = .systemBackground
        let titleLabel = UILabel()
        titleLabel.text = "第 \(seasonNumber) 季"
        titleLabel.font = ThemeFont.bold(ofSize: 32)
        
        headerView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 64
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return episodes.count
    }
    
    override func tableView(_ tableView: UITableView,cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let episode = episodes[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "episodeCell", for: indexPath)
        var config = UIListContentConfiguration.subtitleCell()
        config.text = "\(episode.episodeNumber). \(episode.name)"
        config.secondaryText = episode.airDate ?? ""
        cell.contentConfiguration = config
        if let stillPath = episode.stillPath,
           let url = URL(string: "https://image.tmdb.org/t/p/w300\(stillPath)") {
            SDWebImageManager.shared.loadImage(with: url, options: [], progress: nil) { image, _, _, _, _, _ in
                guard let image = image else { return }
                DispatchQueue.main.async {
                    var updated = config
                    updated.image = image
                    updated.imageProperties.reservedLayoutSize = CGSize(width: 150, height: 85)
                    cell.contentConfiguration = updated
                }
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectedEpisode = episodes[indexPath.row]
        let detailVC = EpisodeDetailView(seasonNumber: seasonNumber, episode: selectedEpisode)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "episodeCell")
        bindViewModel()
        viewModel.fetchEpisodes()
    }
}
