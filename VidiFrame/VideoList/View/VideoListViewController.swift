//
//  VideoListViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

/**
 * 비디오 목록을 표시하고 관리하는 메인 뷰 컨트롤러
 * - 비디오 파일 목록 표시
 * - 비디오 파일 추가/삭제 기능
 * - 파일 저장 진행률 표시
 * - 빈 상태 표시
 */
class VideoListViewController: UIViewController {
    
    // MARK: - UI Components
    
    /// 테이블뷰를 감싸는 컨테이너 뷰 (둥근 모서리, 그림자 효과 적용)
    private let tableWrapperView = UIView().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 20.s
        $0.layer.applyShadow()
    }
    
    /// 비디오 목록을 표시하는 테이블뷰
    private let fileListTableView = UITableView().then {
        $0.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
        $0.backgroundColor = .clear
        $0.layer.cornerRadius = 20.s
        $0.clipsToBounds = true
        $0.layer.masksToBounds = true
        $0.separatorStyle = .singleLine
        $0.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    /// 비디오 파일 추가 버튼 (+ 아이콘)
    private let addFileButton = UIButton().then {
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 15.s
        $0.layer.applyShadow()
        $0.pressAnimation()
    }
    
    /// 로딩 중일 때 표시되는 인디케이터
    private let loadingIndicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
        $0.color = .systemBlue
    }
    
    /// 파일 저장 진행률을 표시하는 프로그레스 바
    private let progressView = UIProgressView(progressViewStyle: .default).then {
        $0.isHidden = true
        $0.progressTintColor = .systemBlue
        $0.trackTintColor = .lightGray
    }
    
    /// 파일 저장 진행률 텍스트 레이블 (몇 MB / 전체 MB, 퍼센트)
    private let progressLabel = UILabel().then {
        $0.isHidden = true
        $0.font = .systemFont(ofSize: 14, weight: .medium)
        $0.textColor = .systemBlue
        $0.textAlignment = .center
    }
    
    /// 프로그레스 바와 레이블을 감싸는 컨테이너 뷰
    private let progressContainerView = UIView().then {
        $0.isHidden = true
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.layer.applyShadow()
    }
    
    /// 비디오가 없을 때 표시되는 빈 상태 뷰
    private let emptyStateView = UIView().then {
        $0.isHidden = true
    }
    
    /// 빈 상태 안내 메시지 레이블
    private let emptyStateLabel = UILabel().then {
        $0.text = "비디오가 없습니다\n아래 버튼을 눌러 비디오를 추가해보세요"
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .systemFont(ofSize: 16, weight: .regular)
        $0.textColor = .gray
    }
    
    // MARK: - Properties
    
    /// 비디오 관련 비즈니스 로직을 처리하는 뷰모델
    private var viewModel: VideoListViewModelProtocol
    
    // MARK: - Initialization
    
    /**
     * 지정 초기화자
     * @param viewModel 비디오 목록 관리를 위한 뷰모델 (기본값: VideoListViewModel())
     */
    init(viewModel: VideoListViewModelProtocol = VideoListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    /**
     * 스토리보드용 초기화자 (필수 구현)
     */
    required init?(coder: NSCoder) {
        self.viewModel = VideoListViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    /**
     * 뷰가 메모리에 로드된 후 호출
     * UI 설정, 뷰모델 바인딩, 초기 데이터 로드 수행
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        bindViewModel()
        viewModel.loadVideos()
    }
    
    // MARK: - Setup Methods
    
    /**
     * 테이블뷰 및 버튼의 delegate, dataSource, target 설정
     */
    private func setupTableView() {
        fileListTableView.delegate = self
        fileListTableView.dataSource = self
        addFileButton.addTarget(self, action: #selector(addFileButtonTapped), for: .touchUpInside)
    }
    
    /**
     * UI 요소들의 레이아웃과 스타일을 설정
     * Auto Layout을 사용하여 뷰 계층 구조 구성
     * 가로/세로 모드 모두 대응하는 유연한 레이아웃
     */
    private func setupUI() {
        view.backgroundColor = .white
        
        // 테이블 래퍼 뷰 설정 - 가로/세로 모드 대응
        view.addSubview(tableWrapperView)
        tableWrapperView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            // 최소 높이 보장
            $0.height.greaterThanOrEqualTo(200)
        }
        
        // 테이블뷰 설정
        tableWrapperView.addSubview(fileListTableView)
        fileListTableView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(5.s)
            $0.leading.trailing.bottom.equalToSuperview()
        }
        
        // 빈 상태 뷰 설정 (비디오가 없을 때 표시)
        tableWrapperView.addSubview(emptyStateView)
        emptyStateView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 빈 상태 안내 레이블
        emptyStateView.addSubview(emptyStateLabel)
        emptyStateLabel.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        // 파일 추가 버튼 설정 - 가로 모드에서도 적절한 크기 유지
        view.addSubview(addFileButton)
        addFileButton.snp.makeConstraints {
            // 가로 모드에서는 버튼 높이를 조금 줄임
            $0.height.equalTo(50.s)
            $0.top.equalTo(tableWrapperView.snp.bottom).offset(16)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
            // 하단 안전 영역과의 거리 조정
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
        
        // 플러스 아이콘 이미지뷰
        let plusImage = UIImageView().then {
            $0.image = UIImage(systemName: "plus")
            $0.tintColor = .black
        }
        addFileButton.addSubview(plusImage)
        plusImage.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.width.height.equalTo(24)
        }
        
        // 로딩 인디케이터 설정
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        // 진행률 컨테이너 뷰 설정
        view.addSubview(progressContainerView)
        progressContainerView.snp.makeConstraints {
            $0.top.equalTo(loadingIndicator.snp.bottom).offset(20.s)
            $0.leading.trailing.equalToSuperview().inset(23.s)
            $0.height.equalTo(60.s)
        }
        
        // 진행률 바 설정
        progressContainerView.addSubview(progressView)
        progressView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16.s)
            $0.centerY.equalToSuperview()
        }
        
        // 진행률 텍스트 레이블 설정
        progressContainerView.addSubview(progressLabel)
        progressLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(16.s)
            $0.centerY.equalToSuperview()
        }
    }
    
    // MARK: - ViewModel Binding
    
    /**
     * 뷰모델과 뷰 간의 데이터 바인딩 설정
     * 뷰모델의 상태 변화를 UI에 반영하는 클로저들을 정의
     */
    private func bindViewModel() {
        // 비디오 목록 업데이트 시 UI 갱신
        viewModel.onVideosUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateUI()
            }
        }
        
        // 로딩 상태 변경 시 인디케이터 표시/숨김
        viewModel.onLoadingStateChanged = { [weak self] isLoading in
            DispatchQueue.main.async {
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
        }
        
        // 에러 발생 시 알림 표시
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: errorMessage)
            }
        }
        
        // 파일 저장 진행률 업데이트
        viewModel.onSaveProgress = { [weak self] progress in
            DispatchQueue.main.async {
                self?.updateSaveProgress(progress)
            }
        }
    }
    
    // MARK: - UI Update Methods
    
    /**
     * 비디오 목록 상태에 따라 UI 업데이트
     * 테이블뷰 데이터 리로드 및 빈 상태 뷰 표시/숨김 처리
     */
    private func updateUI() {
        fileListTableView.reloadData()
        
        let hasVideos = viewModel.numberOfVideos() > 0
        emptyStateView.isHidden = hasVideos
        fileListTableView.isHidden = !hasVideos
    }
    
    /**
     * 파일 저장 진행률 업데이트
     * @param progress 저장 진행률 정보 (진행률, 복사된 바이트, 전체 바이트, 완료 여부)
     */
    private func updateSaveProgress(_ progress: VideoSaveProgress) {
        if progress.progress == 0.0 {
            // 저장 시작 시 진행률 뷰 표시
            showProgressView()
        }
        
        progressView.progress = Float(progress.progress)
        
        let progressPercentage = Int(progress.progress * 100)
        let totalMB = Double(progress.totalBytes) / (1024 * 1024)
        let copiedMB = Double(progress.copiedBytes) / (1024 * 1024)
        
        progressLabel.text = String(format: "저장 중... %.1f/%.1f MB (%d%%)", copiedMB, totalMB, progressPercentage)
        
        if progress.isCompleted {
            // 저장 완료 시 0.5초 후 진행률 뷰 숨김
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.hideProgressView()
            }
        }
    }
    
    /**
     * 파일 저장 진행률 뷰를 페이드인 애니메이션과 함께 표시
     */
    private func showProgressView() {
        progressContainerView.isHidden = false
        progressView.isHidden = false
        progressLabel.isHidden = false
        
        progressContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.progressContainerView.alpha = 1.0
        }
    }
    
    /**
     * 파일 저장 진행률 뷰를 페이드아웃 애니메이션과 함께 숨기고 완료 메시지 표시
     */
    private func hideProgressView() {
        UIView.animate(withDuration: 0.3) {
            self.progressContainerView.alpha = 0
        } completion: { _ in
            self.progressContainerView.isHidden = true
            self.progressView.isHidden = true
            self.progressLabel.isHidden = true
            self.progressView.progress = 0
            
            // 저장 완료 메시지 표시
            self.showSuccessMessage()
        }
    }
    
    /**
     * 저장 완료 알림 메시지 표시
     */
    private func showSuccessMessage() {
        let alert = UIAlertController(title: "저장 완료", message: "비디오가 성공적으로 저장되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    /**
     * 에러 알림 메시지 표시
     * @param message 표시할 에러 메시지
     */
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
        
    // MARK: - Actions
    
    /**
     * 파일 추가 버튼 탭 시 호출
     * 지원되는 비디오 형식의 파일을 선택할 수 있는 문서 선택기 표시
     */
    @objc private func addFileButtonTapped() {
        let supportedTypes: [UTType] = [.movie, .mpeg4Movie, .video]
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
}

// MARK: - UITableView DataSource & Delegate
extension VideoListViewController: UITableViewDelegate, UITableViewDataSource {
    
    /**
     * 테이블뷰 섹션 내 행의 개수 반환
     * @param tableView 테이블뷰 인스턴스
     * @param section 섹션 번호
     * @return 비디오 개수
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfVideos()
    }
    
    /**
     * 테이블뷰 셀 구성
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 셀의 인덱스 경로
     * @return 구성된 비디오 셀
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as? VideoCell else {
            return UITableViewCell()
        }
        
        if let video = viewModel.video(at: indexPath.row) {
            cell.configure(with: video)
            
            // 옵션 버튼 콜백 설정
            cell.onOptionsButtonTapped = { [weak self] in
                self?.showVideoOptions(for: indexPath.row)
            }
        }
        
        return cell
    }
    
    /**
     * 테이블뷰 셀의 높이 지정
     * 가로/세로 모드에 따라 적절한 높이 반환
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 셀의 인덱스 경로
     * @return 셀 높이 (가로 모드: 74, 세로 모드: 84)
     */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 가로 모드에서는 높이를 줄여서 더 많은 셀이 보이도록 함
        let isLandscape = view.frame.width > view.frame.height
        return isLandscape ? 74 : 84
    }
    
    /**
     * 테이블뷰 셀 편집 스타일 처리 (스와이프 삭제)
     * @param tableView 테이블뷰 인스턴스
     * @param editingStyle 편집 스타일 (.delete)
     * @param indexPath 편집할 셀의 인덱스 경로
     */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            showDeleteConfirmation(for: indexPath.row)
        }
    }
    
    /**
     * 테이블뷰 셀 선택 시 호출
     * 현재는 비디오 재생 기능이 미구현 상태로 콘솔 출력만 수행
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 선택된 셀의 인덱스 경로
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 터치 피드백 (중간 강도 햅틱)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // TODO: 비디오 재생 기능 구현
        print("비디오 선택됨: \(indexPath.row)")
    }
    
    // MARK: - Helper Methods
    
    /**
     * 비디오 옵션 액션 시트 표시
     * @param index 옵션을 표시할 비디오의 인덱스
     */
    private func showVideoOptions(for index: Int) {
        guard let video = viewModel.video(at: index) else { return }
        
        let actionSheet = UIAlertController(title: video.name, message: "원하는 작업을 선택하세요", preferredStyle: .actionSheet)
        
        // 비디오 이름 변경 액션
        actionSheet.addAction(UIAlertAction(title: "비디오 이름 변경", style: .default) { [weak self] _ in
            self?.showRenameDialog(for: index)
        })
        
        // 썸네일 변경 액션
        actionSheet.addAction(UIAlertAction(title: "썸네일 변경", style: .default) { [weak self] _ in
            self?.showThumbnailSelection(for: video)
        })
        
        // 비디오 삭제 액션
        actionSheet.addAction(UIAlertAction(title: "비디오 삭제", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: index)
        })
        
        // 취소 액션
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad에서 액션 시트가 제대로 표시되도록 popover 설정
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(actionSheet, animated: true)
    }
    
    /**
     * 비디오 이름 변경 다이얼로그 표시
     * @param index 이름을 변경할 비디오의 인덱스
     */
    private func showRenameDialog(for index: Int) {
        guard let video = viewModel.video(at: index) else { return }
        
        let alert = UIAlertController(title: "비디오 이름 변경", message: "새로운 이름을 입력하세요", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = video.name
            textField.placeholder = "비디오 이름"
            textField.clearButtonMode = .whileEditing
        }
        
        // 확인 액션
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let newName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else {
                self?.showErrorAlert(message: "올바른 이름을 입력해주세요.")
                return
            }
            
            // 뷰모델에 이름 변경 요청
            self?.viewModel.renameVideo(at: index, newName: newName)
            
            // 테이블뷰 해당 셀만 업데이트
            DispatchQueue.main.async {
                let indexPath = IndexPath(row: index, section: 0)
                self?.fileListTableView.reloadRows(at: [indexPath], with: .none)
            }
        }
        
        // 취소 액션
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        present(alert, animated: true) {
            // 텍스트 필드에 포커스를 주고 전체 텍스트 선택
            alert.textFields?.first?.selectAll(nil)
        }
    }
    
    /**
     * 썸네일 선택 화면 표시
     * @param video 썸네일을 변경할 비디오 모델
     */
    private func showThumbnailSelection(for video: VideoModel) {
        let thumbnailSelectionVC = ThumbnailSelectionViewController(videoURL: video.url) { [weak self] selectedImage in
            if selectedImage != nil {
                // 썸네일이 변경되었으므로 테이블뷰 리로드
                DispatchQueue.main.async {
                    self?.fileListTableView.reloadData()
                }
            }
        }
        
        present(thumbnailSelectionVC, animated: true)
    }
    
    /**
     * 비디오 삭제 확인 알림창 표시
     * @param index 삭제할 비디오의 인덱스
     */
    private func showDeleteConfirmation(for index: Int) {
        let videoName = viewModel.videoName(at: index)
        let alert = UIAlertController(
            title: "비디오 삭제",
            message: "'\(videoName)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteVideo(at: index)
        })
        
        present(alert, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension VideoListViewController: UIDocumentPickerDelegate {
    
    /**
     * 문서 선택기에서 파일 선택 완료 시 호출
     * 선택된 비디오 파일을 뷰모델에 추가 요청
     * @param controller 문서 선택기 인스턴스
     * @param urls 선택된 파일들의 URL 배열
     */
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        viewModel.addVideo(sourceURL)
    }
}
