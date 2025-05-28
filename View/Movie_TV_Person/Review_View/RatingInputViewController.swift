//
//  RatingInputViewController.swift
//  MyTMDB_App
//
//  Created by Willy Hsu on 2025/5/28.
//

import Foundation
import UIKit
import SnapKit
import Combine

class RatingInputViewController: UIViewController {
    
    var favoriteViewModel: FavoriteViewModel!
    private var cancellables = Set<AnyCancellable>()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        return label
    }()

    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 10.0
        slider.value = 5.0
        return slider
    }()

    private let submitButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("提交評分", for: .normal)
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.layer.cornerRadius = 8
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        return button
    }()


    private func layout() {
        valueLabel.text = "評分: \(slider.value)"
        view.addSubview(valueLabel)
        view.addSubview(slider)
        view.addSubview(submitButton)

        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)
        submitButton.addTarget(self, action: #selector(submitRating), for: .touchUpInside)

        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        slider.snp.makeConstraints { make in
            make.top.equalTo(valueLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        submitButton.snp.makeConstraints { make in
            make.top.equalTo(slider.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(50)
        }
    }
    
    
    @objc private func sliderChanged(_ sender: UISlider) {
        let stepped = round(sender.value * 2) / 2
        sender.value = stepped
        valueLabel.text = "❤️ \(stepped)"
    }

    @objc private func submitRating() {
        let score = Double(slider.value)
        favoriteViewModel.rate(score)
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layout()
        
        favoriteViewModel.$didRate
            .filter { $0 }
            .sink { [weak self] _ in
                let alert = UIAlertController(title: "完成", message: "評分已儲存！", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "好", style: .default))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)

        favoriteViewModel.$rateError
            .compactMap { $0 }
            .sink { [weak self] message in
                let alert = UIAlertController(title: "失敗", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "知道了", style: .cancel))
                self?.present(alert, animated: true)
            }
            .store(in: &cancellables)
    }
}
