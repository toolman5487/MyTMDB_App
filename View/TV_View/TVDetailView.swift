//
//  TVDetailView.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/7.
//

import Foundation
import UIKit
import SnapKit
import Combine
import SDWebImage

class TVDetailView: UIViewController {
    
    private let viewModel: TVDetailViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(viewModel: TVDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let tvBackdropImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.backgroundColor = .tertiarySystemFill
        image.image = UIImage(systemName: "film.stack")
        return image
    }()

    private let tvTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.numberOfLines = 2
        label.text = "節目標題"
        return label
    }()

    private func layoutUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tvBackdropImageView)
        view.addSubview(tvTitleLabel)
        tvBackdropImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        tvTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(tvBackdropImageView.snp.bottom).offset(16)
            make.leading.equalToSuperview().offset(16)
        }
        
        
    }
    
    private func bindViewModel() {
        viewModel.$tvSeries
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tvSeries in
                print("show title:", tvSeries.name)
                self?.tvTitleLabel.text = tvSeries.name
                if let path = tvSeries.backdropPath {
                    let url = URL(string: "https://image.tmdb.org/t/p/w500\(path)")
                    self?.tvBackdropImageView.sd_setImage(with: url)
                }
            }
            .store(in: &cancellables)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        layoutUI()
        bindViewModel()
        viewModel.fetchDetail()
    }
}
