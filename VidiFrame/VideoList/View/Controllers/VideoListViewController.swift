//
//  VideoListViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit

/**
 * 비디오 목록을 표시하고 관리하는 메인 뷰 컨트롤러
 * - 비디오 파일 목록 표시
 * - 비디오 파일 추가/삭제 기능
 * - 파일 저장 진행률 표시
 * - 빈 상태 표시
 */
class VideoListViewController: UIViewController {
    
    // MARK: - UI Components
    
    private let liquidGlassBackgroundView = LiquidGlassBackgroundView()
    
    private let headerTitleLabel = UILabel().then {
        $0.text = "VidiFrame"
        $0.font = .systemFont(ofSize: 34, weight: .bold)
        $0.textColor = .label
    }
    
    private let headerSubtitleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 15, weight: .medium)
        $0.textColor = .secondaryLabel
        $0.text = "아직 추가된 비디오가 없어요"
    }
    
    private let headerStackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 6
        $0.alignment = .leading
    }
    
    /// 비디오 목록 테이블뷰
    private lazy var fileListTableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(VideoCell.self, forCellReuseIdentifier: VideoCell.identifier)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 8, right: 0)
        return tableView
    }()
    
    private let bottomBarGlassView = LiquidGlassContainerView(
        cornerRadius: 16,
        style: .regular,
        isInteractive: true,
        presence: .elevated
    )
    
    private let addButtonContentStack = UIStackView().then {
        $0.axis = .horizontal
        $0.alignment = .center
        $0.spacing = 12
        $0.isUserInteractionEnabled = false
    }
    
    private let addIconBadgeView = UIView().then {
        $0.backgroundColor = UIColor.label.withAlphaComponent(0.08)
        $0.layer.cornerRadius = 15
        $0.layer.cornerCurve = .continuous
    }
    
    private let addIconImageView = UIImageView().then {
        $0.image = UIImage(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        )
        $0.tintColor = .label
        $0.contentMode = .scaleAspectFit
    }
    
    private let addTitleLabel = UILabel().then {
        $0.text = "비디오 추가"
        $0.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.textColor = .label
    }
    
    /// 비디오 파일 추가 버튼 (터치 영역)
    private let addFileButton = UIButton().then {
        $0.backgroundColor = .clear
        $0.pressAnimation()
    }
    
    /// 비디오가 없을 때 표시되는 빈 상태 뷰
    private let emptyStateView = UIView()
    
    private let emptyStateIcon = UIImageView().then {
        $0.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .light)
        $0.image = UIImage(systemName: "film.stack")
        $0.tintColor = .secondaryLabel
        $0.contentMode = .scaleAspectFit
    }
    
    private let emptyStateTitleLabel = UILabel().then {
        $0.text = "비디오가 없습니다"
        $0.font = .systemFont(ofSize: 17, weight: .semibold)
        $0.textColor = .label
        $0.textAlignment = .center
    }
    
    /// 빈 상태 안내 메시지 레이블
    private let emptyStateLabel = UILabel().then {
        $0.text = "아래 버튼으로 영상을 추가하세요"
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.font = .systemFont(ofSize: 15, weight: .regular)
        $0.textColor = .secondaryLabel
    }
    
    private let emptyStateStackView = UIStackView().then {
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 10
    }
    
    // MARK: - Properties
    
    /// 비디오 관련 비즈니스 로직을 처리하는 뷰모델
    private var viewModel: VideoListViewModelProtocol
    
    /// 테이블뷰 관리 매니저
    private var tableManager: VideoListTableManager!
    
    /// 진행률 관리 매니저
    private var progressManager: VideoProgressManager!
    
    /// 비디오 옵션 관리 매니저
    private var optionsManager: VideoOptionsManager!
    
    /// 문서 피커 관리 매니저
    private var documentPickerManager: VideoDocumentPickerManager!
    
    private let bottomBarHorizontalInset: CGFloat = 20
    private let addButtonFixedHeight: CGFloat = 54
    
    // MARK: - Initialization
    
    /**
     * @param viewModel 비디오 목록 관리를 위한 뷰모델 (기본값: VideoListViewModel())
     */
    init(viewModel: VideoListViewModelProtocol = VideoListViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.viewModel = VideoListViewModel()
        super.init(coder: coder)
    }
    
    // MARK: - Lifecycle
    
    /**
     * 뷰가 메모리에 로드된 후 호출
     * UI 설정, 매니저들 초기화, 뷰모델 바인딩, 초기 데이터 로드 수행
     */
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupManagers()
        bindViewModel()
        viewModel.loadVideos()
    }
    
    // MARK: - Setup Methods
    
    /**
     * 매니저들을 초기화하고 설정
     */
    private func setupManagers() {
        // 테이블뷰 매니저 설정
        tableManager = VideoListTableManager(viewModel: viewModel)
        fileListTableView.delegate = tableManager
        fileListTableView.dataSource = tableManager
        
        // 진행률 매니저 설정
        progressManager = VideoProgressManager(
            parentView: view,
            presentingViewController: self
        )
        
        // 옵션 매니저 설정
        optionsManager = VideoOptionsManager(viewModel: viewModel, presentingViewController: self)
        
        // 문서 피커 매니저 설정
        documentPickerManager = VideoDocumentPickerManager(viewModel: viewModel, presentingViewController: self)
        
        // 매니저들 간의 연결 설정
        setupManagerCallbacks()
        
        // 버튼 타겟 설정
        addFileButton.addTarget(self, action: #selector(addFileButtonTapped), for: .touchUpInside)
    }
    
    /**
     * 매니저들 간의 콜백 설정
     */
    private func setupManagerCallbacks() {
        // 테이블 매니저 콜백
        tableManager.onVideoOptionsSelected = { [weak self] index in
            self?.optionsManager.showVideoOptions(for: index)
        }
        
        tableManager.onDeleteConfirmationRequested = { [weak self] index in
            self?.optionsManager.showDeleteConfirmation(for: index)
        }
        
        tableManager.onVideoSelected = { [weak self] index in
            self?.playVideo(at: index)
        }
        
        // 옵션 매니저 콜백
        optionsManager.onTableViewUpdateRequired = { [weak self] in
            self?.fileListTableView.reloadData()
        }
        
        optionsManager.onRowUpdateRequired = { [weak self] index in
            let indexPath = IndexPath(row: index, section: 0)
            self?.fileListTableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    /**
     * UI 요소들의 레이아웃과 스타일을 설정
     * Auto Layout을 사용하여 뷰 계층 구조 구성
     * 가로/세로 모드 모두 대응하는 유연한 레이아웃
     */
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(liquidGlassBackgroundView)
        liquidGlassBackgroundView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        setupAddButton()
        
        headerStackView.addArrangedSubview(headerTitleLabel)
        headerStackView.addArrangedSubview(headerSubtitleLabel)
        
        view.addSubview(headerStackView)
        headerStackView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(20)
        }
        
        bottomBarGlassView.contentView.addSubview(addFileButton)
        
        addIconBadgeView.addSubview(addIconImageView)
        addButtonContentStack.addArrangedSubview(addIconBadgeView)
        addButtonContentStack.addArrangedSubview(addTitleLabel)
        addFileButton.addSubview(addButtonContentStack)
        
        addButtonContentStack.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        addIconBadgeView.snp.makeConstraints {
            $0.width.height.equalTo(30)
        }
        
        addIconImageView.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
        
        addFileButton.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.addSubview(fileListTableView)
        view.addSubview(bottomBarGlassView)
        
        bottomBarGlassView.snp.makeConstraints {
            $0.centerX.equalTo(view.safeAreaLayoutGuide)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-12)
            $0.height.equalTo(addButtonFixedHeight)
            $0.width.lessThanOrEqualTo(view.snp.height).offset(-bottomBarHorizontalInset * 2)
            $0.width.equalTo(view.safeAreaLayoutGuide).offset(-bottomBarHorizontalInset * 2).priority(.high)
        }
        
        fileListTableView.snp.makeConstraints {
            $0.top.equalTo(headerStackView.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBarGlassView.snp.top).offset(-8)
        }
        
        bottomBarGlassView.setContentHuggingPriority(.required, for: .vertical)
        bottomBarGlassView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        LiquidGlass.configureScrollEdges(for: fileListTableView)
        LiquidGlass.addBottomScrollEdgeInteraction(to: bottomBarGlassView, scrollView: fileListTableView)
        
        emptyStateStackView.addArrangedSubview(emptyStateIcon)
        emptyStateStackView.addArrangedSubview(emptyStateTitleLabel)
        emptyStateStackView.addArrangedSubview(emptyStateLabel)
        emptyStateStackView.setCustomSpacing(16, after: emptyStateIcon)
        
        emptyStateView.addSubview(emptyStateStackView)
        emptyStateIcon.snp.makeConstraints {
            $0.width.height.equalTo(48)
        }
        emptyStateStackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.leading.trailing.equalToSuperview().inset(32)
        }
    }
    
    private func setupAddButton() {
        addFileButton.configuration = nil
        addFileButton.accessibilityLabel = "비디오 추가"
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        addIconBadgeView.backgroundColor = UIColor.label.withAlphaComponent(0.08)
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
        
        // 에러 발생 시 알림 표시
        viewModel.onError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showErrorAlert(message: errorMessage)
            }
        }
        
        // 파일 저장 진행률 업데이트
        viewModel.onSaveProgress = { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressManager.updateProgress(progress)
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
        
        let count = viewModel.numberOfVideos()
        let hasVideos = count > 0
        headerSubtitleLabel.text = hasVideos ? "\(count)개의 비디오" : "아직 추가된 비디오가 없어요"
        fileListTableView.backgroundView = hasVideos ? nil : emptyStateView
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
     * 사용자가 파일 목록 또는 사진첩에서 비디오를 선택할 수 있는 옵션 표시
     */
    @objc private func addFileButtonTapped() {
        let alertController = UIAlertController(
            title: "비디오 추가",
            message: "파일과 앨범 중에서 선택",
            preferredStyle: .actionSheet
        )
        
        // 파일 목록에서 선택
        alertController.addAction(UIAlertAction(title: "파일 목록", style: .default) { [weak self] _ in
            self?.documentPickerManager.presentDocumentPicker()
        })
        
        // 사진첩에서 선택
        alertController.addAction(UIAlertAction(title: "사진첩 비디오", style: .default) { [weak self] _ in
            self?.documentPickerManager.presentPhotoLibraryVideoPicker()
        })
        
        // 취소
        alertController.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad 지원을 위한 popoverPresentationController 설정
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = addFileButton
            popover.sourceRect = addFileButton.bounds
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Video Playback
    
    /**
     * 지정된 인덱스의 비디오를 커스텀 플레이어로 재생합니다
     * @param index 재생할 비디오의 인덱스
     */
    private func playVideo(at index: Int) {
        guard let video = viewModel.video(at: index) else {
            showErrorAlert(message: "비디오를 찾을 수 없습니다.")
            return
        }
        
        // 커스텀 비디오 플레이어 생성 및 표시
        let customPlayer = CustomVideoPlayerViewController(
            videoURL: video.url,
            title: video.name
        )
        
        present(customPlayer, animated: true)
    }

}
