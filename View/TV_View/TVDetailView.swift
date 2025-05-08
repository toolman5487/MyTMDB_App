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
    
    private let tv_ScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.contentInset.bottom = 40
        scrollView.alwaysBounceVertical = false
        scrollView.bounces = false
        return scrollView
    }()
    
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
        label.font = ThemeFont.bold(ofSize: 32)
        label.numberOfLines = 1
        label.text = "節目標題"
        return label
    }()
    
    private let tvFirstAirDateLabel: UILabel = {
        let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 16)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    
    private let tvOverviewLabel: UILabel = {
       let label = UILabel()
        label.font = ThemeFont.regular(ofSize: 12)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.numberOfLines = 3
        label.text = "劇情簡介"
        return label
    }()
    
    
    

    private func layoutUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(tv_ScrollView)
        tv_ScrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        tv_ScrollView.addSubview(tvBackdropImageView)
        tvBackdropImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        
        tv_ScrollView.addSubview(tvTitleLabel)
        tvTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(tvBackdropImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
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
        viewModel.fetchTVDetail()
    }
}
