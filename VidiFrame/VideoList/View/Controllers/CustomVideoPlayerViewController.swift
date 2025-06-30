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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startProgressTimer()
        showControlsTemporarily()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopProgressTimer()
        controlsTimer?.invalidate()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = videoContainerView.bounds
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
            $0.height.equalTo(100)
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
        
        // 하단 버튼들 (반복, 속도, 확대)
        let buttonStackView = UIStackView(arrangedSubviews: [loopButton, speedButton, zoomButton])
        buttonStackView.axis = .horizontal
        buttonStackView.spacing = 16
        buttonStackView.distribution = .fillEqually
        
        bottomControlsView.addSubview(buttonStackView)
        buttonStackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(progressSlider.snp.bottom).offset(16)
            $0.width.equalTo(180)
            $0.height.equalTo(40)
        }
        
        // 각 버튼들
        [loopButton, speedButton, zoomButton].forEach { button in
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
        
        // 비디오 준비 완료 시 총 시간 설정
        player.currentItem?.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                self?.setupDuration()
            }
        }
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
     * 비디오 총 시간 설정
     */
    private func setupDuration() {
        guard let duration = player.currentItem?.duration else { return }
        let totalSeconds = CMTimeGetSeconds(duration)
        
        if !totalSeconds.isNaN && !totalSeconds.isInfinite {
            progressSlider.maximumValue = Float(totalSeconds)
            durationLabel.text = formatTime(totalSeconds)
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
        
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            if self?.player.timeControlStatus == .playing {
                UIView.animate(withDuration: 0.3) {
                    self?.controlsOverlayView.alpha = 0
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
        guard let currentTime = player.currentItem?.currentTime() else { return }
        let currentSeconds = CMTimeGetSeconds(currentTime)
        
        if !currentSeconds.isNaN && !currentSeconds.isInfinite {
            progressSlider.value = Float(currentSeconds)
            currentTimeLabel.text = formatTime(currentSeconds)
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
    
    // MARK: - Actions
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func playPauseButtonTapped() {
        if player.timeControlStatus == .playing {
            player.pause()
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        } else {
            player.play()
            playPauseButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            showControlsTemporarily()
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
        
        UIView.animate(withDuration: 0.3) {
            self.playerLayer.videoGravity = self.isZoomed ? .resizeAspectFill : .resizeAspect
        }
        
        zoomButton.setImage(
            UIImage(systemName: isZoomed ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"),
            for: .normal
        )
        zoomButton.tintColor = isZoomed ? .systemBlue : .white
        
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
            player.seek(to: .zero)
            player.play()
        } else {
            playPauseButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
            showControlsTemporarily()
        }
    }
    
    // MARK: - Deinitialization
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        controlsTimer?.invalidate()
        stopProgressTimer()
    }
} 
