//
//  CustomVideoPlayerViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import AVFoundation

/**
 * 커스텀 비디오 플레이어 뷰 컨트롤러
 * - 완전히 커스텀한 UI 컨트롤
 * - 화면 닫기, 재생/일시정지, 프로그레스 바, 반복재생, 속도조절, 확대 기능 제공
 */
class CustomVideoPlayerViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 비디오 플레이어
    private var player: AVPlayer!
    
    /// 비디오 플레이어 레이어
    private var playerLayer: AVPlayerLayer!
    
    /// 비디오 URL
    private let videoURL: URL
    
    /// 비디오 제목
    private let videoTitle: String
    
    /// 반복 재생 여부
    private var isLoopEnabled = false
    
    /// 현재 재생 속도
    private var currentPlaybackRate: Float = 1.0
    
    /// 확대 모드 여부
    private var isZoomed = false
    
    /// 컨트롤 표시 타이머
    private var controlsTimer: Timer?
    
    /// 프로그레스 업데이트 타이머
    private var progressTimer: Timer?
    
    /// KVO 관찰자들
    private var playerItemObservers: [NSKeyValueObservation] = []
    
    /// 번인 방지용 화면 이동 타이머
    private var burnInPreventionTimer: Timer?
    
    /// 원본 비디오 프레임 (확대된 크기)
    private var originalVideoFrame: CGRect = .zero
    
    /// 현재 비디오 프레임 위치 (이동 추적용)
    private var currentVideoFrame: CGRect = .zero
    
    /// 번인 방지 활성화 여부
    private var isBurnInPreventionEnabled = false
    
    /// 이전 화면 크기 (회전 감지용)
    private var previousBounds: CGRect = .zero
    
    // MARK: - UI Components
    
    /// 비디오 표시 뷰
    private let videoContainerView = UIView().then {
        $0.backgroundColor = .black
    }
    
    /// 컨트롤 오버레이 뷰
    private let controlsOverlayView = UIView().then {
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
    }
    
    /// 상단 컨트롤 뷰
    private let topControlsView = UIView()
    
    /// 하단 컨트롤 뷰
    private let bottomControlsView = UIView()
    
    /// 닫기 버튼
    private let closeButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "xmark"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
    }
    
    /// 비디오 제목 레이블
    private let titleLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 18, weight: .semibold)
        $0.numberOfLines = 1
    }
    
    /// 재생/일시정지 버튼
    private let playPauseButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "play.fill"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 25
    }
    
    /// 프로그레스 슬라이더
    private let progressSlider = UISlider().then {
        $0.minimumTrackTintColor = .systemBlue
        $0.maximumTrackTintColor = UIColor.white.withAlphaComponent(0.3)
        $0.thumbTintColor = .white
    }
    
    /// 현재 시간 레이블
    private let currentTimeLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.text = "00:00"
    }
    
    /// 총 시간 레이블
    private let durationLabel = UILabel().then {
        $0.textColor = .white
        $0.font = .systemFont(ofSize: 12, weight: .medium)
        $0.text = "00:00"
    }
    
    /// 반복 재생 버튼
    private let loopButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "repeat"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
    }
    
    /// 속도 조절 버튼
    private let speedButton = UIButton(type: .system).then {
        $0.setTitle("1x", for: .normal)
        $0.setTitleColor(.white, for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
    }
    
    /// 확대 버튼
    private let zoomButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "arrow.up.left.and.arrow.down.right"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
    }
    
    /// 번인 방지 버튼
    private let burnInPreventionButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "move.3d"), for: .normal)
        $0.tintColor = .white
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        $0.layer.cornerRadius = 20
    }
    
    // MARK: - Initialization
    
    /**
     * 초기화
     * @param videoURL 재생할 비디오 URL
     * @param title 비디오 제목
     */
    init(videoURL: URL, title: String) {
        self.videoURL = videoURL
        self.videoTitle = title
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .fullScreen
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlayer()
        setupActions()
        setupGestures()
        
        // 초기 버튼 상태 설정
        updateZoomButtonAppearance()
        updateBurnInButtonState()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startProgressTimer()
        showControlsTemporarily()
        
        // 초기 화면 크기 저장
        previousBounds = videoContainerView.bounds
        
        // 화면이 나타날 때 duration 다시 확인 및 자동 재생 시도
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.setupDuration()
            self.startAutoPlay()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopProgressTimer()
        controlsTimer?.invalidate()
        stopBurnInPrevention()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let currentBounds = videoContainerView.bounds
        let isRotationDetected = !previousBounds.equalTo(currentBounds) && !previousBounds.equalTo(.zero)
        
        if !isZoomed {
            // 일반 모드: 정상 레이아웃 설정
            setupVideoLayerFrame()
        } else if isRotationDetected {
            // 확대 모드 + 화면 회전 감지: 레이아웃 재설정
            resetZoomModeForRotation()
        }
        
        // 현재 화면 크기 저장
        previousBounds = currentBounds
    }
    
    /**
     * 화면 회전 시 확대 모드 레이아웃 재설정
     */
    private func resetZoomModeForRotation() {
        guard let playerLayer = playerLayer else { return }
        
        // 1. 화면 초기화 (원래 위치로)
        let containerBounds = videoContainerView.bounds
        playerLayer.frame = containerBounds
        
        // 2. 확대 모드 레이아웃 재설정
        setupVideoLayerFrame()
        
        // 3. 현재 위치 업데이트
        currentVideoFrame = originalVideoFrame
        
        // 4. 번인 방지가 활성화되어 있다면 타이머 재시작 (새로운 방향에 맞게)
        if isBurnInPreventionEnabled {
            stopBurnInPrevention()
            startBurnInPrevention()
        }
    }
    
    // MARK: - Setup Methods
    
    /**
     * UI 구성
     */
    private func setupUI() {
        view.backgroundColor = .black
        titleLabel.text = videoTitle
        
        // 메인 뷰 구성
        view.addSubview(videoContainerView)
        view.addSubview(controlsOverlayView)
        
        // 컨트롤 뷰들 구성
        controlsOverlayView.addSubview(topControlsView)
        controlsOverlayView.addSubview(bottomControlsView)
        
        // 상단 컨트롤들
        topControlsView.addSubview(closeButton)
        topControlsView.addSubview(titleLabel)
        
        // 하단 컨트롤들
        bottomControlsView.addSubview(playPauseButton)
        bottomControlsView.addSubview(currentTimeLabel)
        bottomControlsView.addSubview(progressSlider)
        bottomControlsView.addSubview(durationLabel)
        bottomControlsView.addSubview(loopButton)
        bottomControlsView.addSubview(speedButton)
        bottomControlsView.addSubview(zoomButton)
        bottomControlsView.addSubview(burnInPreventionButton)
        
        // 레이아웃 설정
        setupConstraints()
    }
    
    /**
     * 오토레이아웃 제약 조건 설정
     */
    private func setupConstraints() {
        // 비디오 컨테이너
        videoContainerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 컨트롤 오버레이
        controlsOverlayView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        // 상단 컨트롤 뷰
        topControlsView.snp.makeConstraints {
            $0.top.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(60)
        }
        
        // 하단 컨트롤 뷰
        bottomControlsView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 닫기 버튼
        closeButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(40)
        }
        
        // 제목 레이블
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(closeButton.snp.trailing).offset(12)
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        
        // 재생/일시정지 버튼
        playPauseButton.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalToSuperview().offset(10)
            $0.width.height.equalTo(50)
        }
        
        // 현재 시간
        currentTimeLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(16)
            $0.top.equalTo(playPauseButton.snp.bottom).offset(16)
        }
        
        // 총 시간
        durationLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.top.equalTo(playPauseButton.snp.bottom).offset(16)
        }
        
        // 프로그레스 슬라이더
        progressSlider.snp.makeConstraints {
            $0.leading.equalTo(currentTimeLabel.snp.trailing).offset(12)
            $0.trailing.equalTo(durationLabel.snp.leading).offset(-12)
            $0.centerY.equalTo(currentTimeLabel)
        }
        
        // 하단 버튼들 (반복, 속도, 확대, 번인방지)
        let buttonStackView = UIStackView(arrangedSubviews: [loopButton, speedButton, zoomButton, burnInPreventionButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 12
        buttonStackView.distribution = .fillEqually
        
        bottomControlsView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(progressSlider.snp.bottom).offset(16)
            $0.bottom.equalToSuperview()
            $0.width.equalTo(240)  // 4개 버튼이므로 너비 증가
            $0.height.equalTo(40)
        }
        
        // 각 버튼들
        [loopButton, speedButton, zoomButton, burnInPreventionButton].forEach { button in
            button.snp.makeConstraints {
                $0.height.equalTo(40)
            }
        }
    }
    
    /**
     * 비디오 플레이어 설정
     */
    private func setupPlayer() {
        player = AVPlayer(url: videoURL)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspect
        videoContainerView.layer.addSublayer(playerLayer)
        
        // 비디오 메타데이터 로드 완료 알림 등록
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem
        )
        
        // KVO를 사용하여 플레이어 아이템 상태 관찰
        setupPlayerItemObservers()
    }
    
    /**
     * 버튼 액션 설정
     */
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        playPauseButton.addTarget(self, action: #selector(playPauseButtonTapped), for: .touchUpInside)
        loopButton.addTarget(self, action: #selector(loopButtonTapped), for: .touchUpInside)
        speedButton.addTarget(self, action: #selector(speedButtonTapped), for: .touchUpInside)
        zoomButton.addTarget(self, action: #selector(zoomButtonTapped), for: .touchUpInside)
        burnInPreventionButton.addTarget(self, action: #selector(burnInPreventionButtonTapped), for: .touchUpInside)
        
        progressSlider.addTarget(self, action: #selector(progressSliderChanged), for: .valueChanged)
        progressSlider.addTarget(self, action: #selector(progressSliderTouchBegan), for: .touchDown)
        progressSlider.addTarget(self, action: #selector(progressSliderTouchEnded), for: [.touchUpInside, .touchUpOutside])
    }
    
    /**
     * 제스처 설정
     */
    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(screenTapped))
        videoContainerView.addGestureRecognizer(tapGesture)
    }
    
    /**
     * KVO를 사용하여 플레이어 아이템의 상태와 duration 관찰 설정
     */
    private func setupPlayerItemObservers() {
        guard let playerItem = player.currentItem else { return }
        
        // 플레이어 아이템 상태 관찰
        let statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handlePlayerItemStatusChange(item)
            }
        }
        
        // duration 관찰
        let durationObserver = playerItem.observe(\.duration, options: [.new, .initial]) { [weak self] item, _ in
            DispatchQueue.main.async {
                self?.handleDurationChange(item)
            }
        }
        
        playerItemObservers.append(statusObserver)
        playerItemObservers.append(durationObserver)
    }
    
    /**
     * 플레이어 아이템 상태 변화 처리
     */
    private func handlePlayerItemStatusChange(_ playerItem: AVPlayerItem) {
        switch playerItem.status {
        case .readyToPlay:
            print("비디오 준비 완료")
            setupDuration()
            // 비디오가 준비되면 자동으로 재생 시작
            startAutoPlay()
        case .failed:
            print("비디오 로드 실패: \(playerItem.error?.localizedDescription ?? "알 수 없는 오류")")
        case .unknown:
            print("비디오 상태 알 수 없음")
        @unknown default:
            break
        }
    }
    
    /**
     * duration 변화 처리
     */
    private func handleDurationChange(_ playerItem: AVPlayerItem) {
        let duration = playerItem.duration
        let totalSeconds = CMTimeGetSeconds(duration)
        
        // duration이 유효한 값인지 확인
        if !totalSeconds.isNaN && !totalSeconds.isInfinite && totalSeconds > 0 {
            progressSlider.maximumValue = Float(totalSeconds)
            durationLabel.text = formatTime(totalSeconds)
            print("비디오 총 시간 설정: \(formatTime(totalSeconds))")
        }
    }
    
    /**
     * 비디오 총 시간 설정 (기존 메서드 개선)
     */
    private func setupDuration() {
        guard let playerItem = player.currentItem else { return }
        
        // 플레이어 아이템이 준비된 상태인지 확인
        guard playerItem.status == .readyToPlay else { return }
        
        let duration = playerItem.duration
        let totalSeconds = CMTimeGetSeconds(duration)
        
        if !totalSeconds.isNaN && !totalSeconds.isInfinite && totalSeconds > 0 {
            progressSlider.maximumValue = Float(totalSeconds)
            durationLabel.text = formatTime(totalSeconds)
            print("setupDuration 호출 - 총 시간: \(formatTime(totalSeconds))")
        } else {
            // duration을 직접 가져올 수 없는 경우 asset에서 로드 시도
            let asset = playerItem.asset
            Task {
                do {
                    let duration = try await asset.load(.duration)
                    let totalSeconds = CMTimeGetSeconds(duration)
                    
                    await MainActor.run {
                        if !totalSeconds.isNaN && !totalSeconds.isInfinite && totalSeconds > 0 {
                            self.progressSlider.maximumValue = Float(totalSeconds)
                            self.durationLabel.text = self.formatTime(totalSeconds)
                            print("Asset에서 duration 로드 완료: \(self.formatTime(totalSeconds))")
                        }
                    }
                } catch {
                    print("Asset duration 로드 실패: \(error)")
                }
            }
        }
    }
    
    /**
     * 자동 재생 시작
     */
    private func startAutoPlay() {
        guard let playerItem = player.currentItem,
              playerItem.status == .readyToPlay else { return }
        
        // 이미 재생 중이면 리턴
        guard player.timeControlStatus != .playing else { return }
        
        // 플레이어 재생 시작 (현재 재생 속도 적용)
        player.rate = currentPlaybackRate
        
        // 재생/일시정지 버튼 아이콘 업데이트
        playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        
        print("자동 재생 시작 (속도: \(currentPlaybackRate)x)")
    }
    
    // MARK: - Video Layer Setup
    
    /**
     * 비디오 레이어 프레임 설정 (줌 상태에 따라)
     */
    private func setupVideoLayerFrame() {
        guard let playerLayer = playerLayer else { return }
        
        let containerBounds = videoContainerView.bounds
        
        if isZoomed {
            // 확대 모드: 번인 방지를 위한 여백 확보
            originalVideoFrame = calculateAspectFillFrameWithMargin(for: containerBounds)
            playerLayer.videoGravity = .resizeAspectFill
        } else {
            // 일반 모드: 원본 크기
            originalVideoFrame = containerBounds
            playerLayer.videoGravity = .resizeAspect
        }
        
        // 현재 위치 초기화
        currentVideoFrame = originalVideoFrame
        
        // 부드러운 전환 애니메이션 적용
        UIView.animate(withDuration: 0.3) {
            playerLayer.frame = self.originalVideoFrame
        }
        
        // 번인 버튼 활성화 상태 업데이트
        updateBurnInButtonState()
    }
    
    /**
     * AspectFill 모드에서 이동 여백을 확보한 프레임 계산
     */
    private func calculateAspectFillFrameWithMargin(for containerBounds: CGRect) -> CGRect {
        // 디바이스 방향에 따라 여백 확보 방향 결정
        let isLandscape = containerBounds.width > containerBounds.height
        
        if isLandscape {
            // 가로 모드: 상하로 이동할 여백 확보 (위아래 손실 부분 + 여백)
            let marginRatio: CGFloat = 0.15 // 15% 여백 추가
            let expandedHeight = containerBounds.height * (1.0 + marginRatio)
            let offsetY = (containerBounds.height - expandedHeight) / 2
            
            return CGRect(
                x: containerBounds.origin.x,
                y: containerBounds.origin.y + offsetY,
                width: containerBounds.width,
                height: expandedHeight
            )
        } else {
            // 세로 모드: 좌우로 이동할 여백 확보 (좌우 손실 부분 + 여백)
            let marginRatio: CGFloat = 0.15 // 15% 여백 추가
            let expandedWidth = containerBounds.width * (1.0 + marginRatio)
            let offsetX = (containerBounds.width - expandedWidth) / 2
            
            return CGRect(
                x: containerBounds.origin.x + offsetX,
                y: containerBounds.origin.y,
                width: expandedWidth,
                height: containerBounds.height
            )
        }
    }
    
    // MARK: - Burn-in Prevention
    
    /**
     * 번인 방지 화면 이동 시작 (3초마다)
     */
    private func startBurnInPrevention() {
        stopBurnInPrevention() // 기존 타이머 정리
        
        //3분 마다 화면 이동
        burnInPreventionTimer = Timer.scheduledTimer(withTimeInterval: 180.0, repeats: true) { [weak self] _ in
            self?.shiftVideoPosition()
        }
    }
    
    /**
     * 번인 방지 화면 이동 정지
     */
    private func stopBurnInPrevention() {
        burnInPreventionTimer?.invalidate()
        burnInPreventionTimer = nil
    }
    
    /**
     * 비디오 위치를 디바이스 방향에 따라 이동 (꽉찬 화면의 손실 부분만큼)
     */
    private func shiftVideoPosition() {
        guard let playerLayer = playerLayer else { return }
        guard isZoomed && isBurnInPreventionEnabled else { return } // 줌 + 번인 방지 모두 활성화되어야 이동
        
        let containerBounds = videoContainerView.bounds
        let isLandscape = containerBounds.width > containerBounds.height
        
        // 이동 가능한 범위 계산
        let maxShiftX = abs(originalVideoFrame.width - containerBounds.width) * 0.4
        let maxShiftY = abs(originalVideoFrame.height - containerBounds.height) * 0.4
        
        var newCenterX = currentVideoFrame.midX
        var newCenterY = currentVideoFrame.midY
        
        if isLandscape {
            // 가로 모드: 상하로만 이동
            // 화면 중앙을 기준으로 허용 범위 내에서 완전히 새로운 Y 위치 생성
            let minY = containerBounds.midY - maxShiftY
            let maxY = containerBounds.midY + maxShiftY
            
            // 현재 위치와 다른 새로운 위치 생성 (최소 20pt 차이)
            var attempts = 0
            repeat {
                newCenterY = CGFloat.random(in: minY...maxY)
                attempts += 1
            } while abs(newCenterY - currentVideoFrame.midY) < 20 && attempts < 10
        } else {
            // 세로 모드: 좌우로만 이동
            // 화면 중앙을 기준으로 허용 범위 내에서 완전히 새로운 X 위치 생성
            let minX = containerBounds.midX - maxShiftX
            let maxX = containerBounds.midX + maxShiftX
            
            // 현재 위치와 다른 새로운 위치 생성 (최소 20pt 차이)
            var attempts = 0
            repeat {
                newCenterX = CGFloat.random(in: minX...maxX)
                attempts += 1
            } while abs(newCenterX - currentVideoFrame.midX) < 20 && attempts < 10
        }
        
        // 새로운 프레임 계산
        let newFrame = CGRect(
            x: newCenterX - originalVideoFrame.width / 2,
            y: newCenterY - originalVideoFrame.height / 2,
            width: originalVideoFrame.width,
            height: originalVideoFrame.height
        )
        
        // 부드러운 애니메이션으로 이동
        UIView.animate(withDuration: 2.0, delay: 0, options: [.curveEaseInOut]) { [weak self] in
            playerLayer.frame = newFrame
        } completion: { [weak self] _ in
            // 이동 완료 후 현재 위치 업데이트
            self?.currentVideoFrame = newFrame
        }
    }
    
    // MARK: - Control Methods
    
    /**
     * 컨트롤 표시/숨김
     */
    private func toggleControls() {
        let isHidden = controlsOverlayView.alpha == 0
        
        UIView.animate(withDuration: 0.3) {
            self.controlsOverlayView.alpha = isHidden ? 1 : 0
        } completion: { _ in
            // 홈바와 상태바 업데이트
            self.setNeedsUpdateOfHomeIndicatorAutoHidden()
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
        if isHidden {
            showControlsTemporarily()
        }
    }
    
    /**
     * 컨트롤을 일시적으로 표시 (3초 후 자동 숨김)
     */
    private func showControlsTemporarily() {
        controlsTimer?.invalidate()
        controlsOverlayView.alpha = 1
        
        // 컨트롤이 나타날 때도 홈바/상태바 업데이트
        setNeedsUpdateOfHomeIndicatorAutoHidden()
        setNeedsStatusBarAppearanceUpdate()
        
        //컨트롤러 사라지고 3초뒤에 홈바가 사라짐
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            if self?.player.timeControlStatus == .playing {
                UIView.animate(withDuration: 0.3) {
                    self?.controlsOverlayView.alpha = 0
                } completion: { _ in
                    // 컨트롤이 숨겨질 때 홈바와 상태바 업데이트
                    self?.setNeedsUpdateOfHomeIndicatorAutoHidden()
                    self?.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
    }
    
    /**
     * 프로그레스 타이머 시작
     */
    private func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    /**
     * 프로그레스 타이머 정지
     */
    private func stopProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    /**
     * 프로그레스 업데이트
     */
    private func updateProgress() {
        guard let playerItem = player.currentItem else { return }
        
        let currentTime = playerItem.currentTime()
        let currentSeconds = CMTimeGetSeconds(currentTime)
        
        if !currentSeconds.isNaN && !currentSeconds.isInfinite {
            progressSlider.value = Float(currentSeconds)
            currentTimeLabel.text = formatTime(currentSeconds)
        }
        
        // duration이 아직 설정되지 않았다면 다시 시도
        if progressSlider.maximumValue <= 0 {
            let duration = playerItem.duration
            let totalSeconds = CMTimeGetSeconds(duration)
            
            if !totalSeconds.isNaN && !totalSeconds.isInfinite && totalSeconds > 0 {
                progressSlider.maximumValue = Float(totalSeconds)
                durationLabel.text = formatTime(totalSeconds)
                print("프로그레스 업데이트 중 duration 재설정: \(formatTime(totalSeconds))")
            }
        }
    }
    
    /**
     * 시간 포맷 함수
     */
    private func formatTime(_ seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    /**
     * 영상이 끝까지 재생되었는지 확인
     */
    private func isVideoAtEnd() -> Bool {
        guard let playerItem = player.currentItem else { return false }
        
        let currentTime = CMTimeGetSeconds(playerItem.currentTime())
        let duration = CMTimeGetSeconds(playerItem.duration)
        
        // duration이 유효하지 않으면 false 반환
        guard !duration.isNaN && !duration.isInfinite && duration > 0 else { return false }
        
        // 현재 시간이 전체 시간의 99% 이상이면 끝으로 간주 (1초 오차 허용)
        return currentTime >= (duration - 1.0)
    }
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func playPauseButtonTapped() {
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            // 영상이 끝까지 재생되었는지 확인
            if isVideoAtEnd() {
                // 처음부터 다시 재생
                player.seek(to: .zero) { [weak self] _ in
                    self?.player.play()
                    self?.playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                    self?.showControlsTemporarily()
                }
            } else {
                // 일반 재생
                player.play()
                playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                showControlsTemporarily()
            }
        }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    @objc private func loopButtonTapped() {
        isLoopEnabled.toggle()
        
        loopButton.tintColor = isLoopEnabled ? .systemBlue : .white
        loopButton.backgroundColor = isLoopEnabled ? 
            UIColor.systemBlue.withAlphaComponent(0.3) : 
            UIColor.black.withAlphaComponent(0.6)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @objc private func speedButtonTapped() {
        let speeds: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
        guard let currentIndex = speeds.firstIndex(of: currentPlaybackRate) else { return }
        
        let nextIndex = (currentIndex + 1) % speeds.count
        currentPlaybackRate = speeds[nextIndex]
        
        player.rate = player.timeControlStatus == .playing ? currentPlaybackRate : 0
        speedButton.setTitle("\(currentPlaybackRate)x", for: .normal)
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @objc private func zoomButtonTapped() {
        isZoomed.toggle()
        
        // 줌 해제 시 번인 방지도 자동 해제
        if !isZoomed && isBurnInPreventionEnabled {
            isBurnInPreventionEnabled = false
            stopBurnInPrevention()
        }
        
        // 비디오 레이어 재설정
        setupVideoLayerFrame()
        
        updateZoomButtonAppearance()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /**
     * 줌 버튼 외관 업데이트
     */
    private func updateZoomButtonAppearance() {
        zoomButton.setImage(
            UIImage(systemName: isZoomed ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"),
            for: .normal
        )
        
        zoomButton.tintColor = isZoomed ? .systemBlue : .white
        zoomButton.backgroundColor = isZoomed ? 
            UIColor.systemBlue.withAlphaComponent(0.3) : 
            UIColor.black.withAlphaComponent(0.6)
    }
    
    /**
     * 번인 방지 버튼 활성화 상태 업데이트
     */
    private func updateBurnInButtonState() {
        let isEnabled = isZoomed
        
        if isEnabled {
            // 줌 활성화 시: 번인 방지 버튼 활성화
            burnInPreventionButton.tintColor = isBurnInPreventionEnabled ? .systemBlue : .white
            burnInPreventionButton.backgroundColor = isBurnInPreventionEnabled ?
                UIColor.systemBlue.withAlphaComponent(0.3) :
                UIColor.black.withAlphaComponent(0.6)
            burnInPreventionButton.isEnabled = true
            burnInPreventionButton.alpha = 1.0
        } else {
            // 줌 비활성화 시: 번인 방지 버튼 비활성화
            burnInPreventionButton.tintColor = .gray
            burnInPreventionButton.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            burnInPreventionButton.isEnabled = false
            burnInPreventionButton.alpha = 0.5
        }
    }
    
    @objc private func burnInPreventionButtonTapped() {
        // 줌이 비활성화된 상태에서는 번인 방지 사용 불가
        guard isZoomed else {
            print("화면을 먼저 확대해주세요")
            
            // 알림 햅틱 피드백
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
            return
        }
        
        isBurnInPreventionEnabled.toggle()
        
        // 현재 화면 크기 업데이트 (회전 감지 오작동 방지)
        previousBounds = videoContainerView.bounds
        
        if isBurnInPreventionEnabled {
            startBurnInPrevention()
        } else {
            stopBurnInPrevention()
        }
        
        // 번인 버튼 상태 업데이트
        updateBurnInButtonState()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    @objc private func progressSliderChanged() {
        let targetTime = CMTime(seconds: Double(progressSlider.value), preferredTimescale: 1000)
        player.seek(to: targetTime)
    }
    
    @objc private func progressSliderTouchBegan() {
        stopProgressTimer()
    }
    
    @objc private func progressSliderTouchEnded() {
        startProgressTimer()
        showControlsTemporarily()
    }
    
    @objc private func screenTapped() {
        toggleControls()
    }
    
    @objc private func playerItemDidReachEnd() {
        if isLoopEnabled {
            // 반복 재생이 켜져있으면 자동으로 처음부터 재생
            player.seek(to: .zero) { [weak self] _ in
                self?.player.play()
            }
        } else {
            // 반복 재생이 꺼져있으면 정지 상태로 두고 재생 버튼 표시
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            showControlsTemporarily()
            print("영상 재생 완료 - 재생 버튼을 누르면 처음부터 다시 재생됩니다")
        }
    }
    
    // MARK: - Status Bar & Home Indicator
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return controlsOverlayView.alpha == 0
    }
    
    override var prefersStatusBarHidden: Bool {
        return controlsOverlayView.alpha == 0
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    // MARK: - Deinitialization
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        controlsTimer?.invalidate()
        stopProgressTimer()
        stopBurnInPrevention()
        
        // KVO 관찰자 해제
        playerItemObservers.forEach { $0.invalidate() }
        playerItemObservers.removeAll()
    }
} 
