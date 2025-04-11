//
//  VideoListViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class VideoListViewController: UIViewController {
    
    // MARK: - UI
    
    private let tableWrapperView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20.s
        $0.layer.applyShadow()
    }
    
    private let fileListTableView = UITableView().then {
        $0.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 20.s
        $0.clipsToBounds = true
        $0.layer.masksToBounds = true
    }
    
    private let addFileButton = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20.s
        $0.layer.applyShadow()
        $0.pressAnimation()
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
        
        addFileButton.addTarget(self, action: #selector(addFileButtonTapped), for: .touchUpInside)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(tableWrapperView)
        tableWrapperView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(50.s)
            $0.leading.trailing.equalToSuperview().inset(23.s)
        }
        
        tableWrapperView.addSubview(fileListTableView)
        fileListTableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(addFileButton)
        addFileButton.snp.makeConstraints {
            $0.height.equalTo(60.s)
            $0.top.equalTo(tableWrapperView.snp.bottom).offset(25.s)
            $0.leading.trailing.equalToSuperview().inset(23.s)
            $0.bottom.equalToSuperview().inset(70.s)
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
    
    // MARK: - Action
    @objc private func addFileButtonTapped() {
        let supportedTypes: [UTType] = [.movie, .mpeg4Movie, .video]
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
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

extension VideoListViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        
        viewModel.saveVideo(sourceURL) {
            DispatchQueue.main.async {
                self.fileListTableView.reloadData()
            }
        }
    }
}
