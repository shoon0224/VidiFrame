//
//  VideoListViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit

class VideoListViewController: UIViewController {

    // MARK: - UI
    private let fileListTableView = UITableView().then {
        $0.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
    }

    private let addFileButton = UIButton().then {
        $0.backgroundColor = .gray
        $0.layer.cornerRadius = 25.s
    }

    // MARK: - ViewModel
    private let viewModel = VideoListViewModel()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAttribute()
        bindViewModel()
        viewModel.loadSavedVideos()
    }

    // MARK: - Setup
    private func setupAttribute() {
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
    }

    private func setupUI() {
        view.backgroundColor = .white

        view.addSubview(fileListTableView)
        fileListTableView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(50.s)
            $0.leading.trailing.equalToSuperview().inset(16.s)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60.s)
        }

        view.addSubview(addFileButton)
        addFileButton.snp.makeConstraints {
            $0.width.height.equalTo(50.s)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-60.s)
            $0.trailing.equalToSuperview().inset(30.s)
        }

        let plusImage = UIImageView().then {
            $0.image = UIImage(systemName: "plus")
            $0.tintColor = .black
        }
        addFileButton.addSubview(plusImage)
        plusImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(30.s)
        }
    }

    private func bindViewModel() {
        viewModel.onVideosUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.fileListTableView.reloadData()
            }
        }
    }
}

// MARK: - UITableView Delegate & DataSource
extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfVideos()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as? VideoCell else {
            return UITableViewCell()
        }
        let title = viewModel.videoName(at: indexPath.row)
        cell.configure(title: title)
        return cell
    }
}
