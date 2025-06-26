//
//  ThumbnailSelectionViewController.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import AVFoundation
import SnapKit

/**
 * 비디오 썸네일 선택 화면 뷰 컨트롤러
 * - 비디오의 여러 시점에서 썸네일을 생성하여 사용자가 선택할 수 있음
 * - 컬렉션 뷰로 썸네일 그리드 표시
 * - 선택된 썸네일을 캐시에 저장
 */
class ThumbnailSelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 비디오 파일 URL
    private let videoURL: URL
    
    /// 완료 콜백 클로저
    private let completion: ((UIImage?) -> Void)
    
    /// 생성된 썸네일 이미지 배열
    private var thumbnailImages: [UIImage?] = []
    
    /// 썸네일 생성 시점 배열 (초 단위)
    private let timeStamps: [Double] = [1, 3, 5, 10, 15, 20, 30, 45, 60]
    
    /// 선택된 썸네일 인덱스
    private var selectedIndex: Int?
    
    // MARK: - UI Components
    
    /// 네비게이션 바
    private let navigationBar = UINavigationBar()
    
    /// 제목 레이블
    private let titleLabel = UILabel().then {
        $0.text = "썸네일 선택"
        $0.font = .systemFont(ofSize: 18, weight: .bold)
        $0.textAlignment = .center
    }
    
    /// 설명 레이블
    private let descriptionLabel = UILabel().then {
        $0.text = "원하는 썸네일을 선택하세요"
        $0.font = .systemFont(ofSize: 14)
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }
    
    /// 썸네일 컬렉션 뷰
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: ThumbnailCell.identifier)
        return collectionView
    }()
    
    /// 로딩 인디케이터
    private let loadingIndicator = UIActivityIndicatorView(style: .large).then {
        $0.hidesWhenStopped = true
    }
    
    /// 하단 버튼 컨테이너
    private let buttonContainer = UIView().then {
        $0.backgroundColor = .systemBackground
        $0.layer.shadowColor = UIColor.black.cgColor
        $0.layer.shadowOffset = CGSize(width: 0, height: -1)
        $0.layer.shadowOpacity = 0.1
        $0.layer.shadowRadius = 1
    }
    
    /// 취소 버튼
    private let cancelButton = UIButton(type: .system).then {
        $0.setTitle("취소", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16)
        $0.backgroundColor = .systemGray5
        $0.layer.cornerRadius = 8
    }
    
    /// 확인 버튼
    private let confirmButton = UIButton(type: .system).then {
        $0.setTitle("확인", for: .normal)
        $0.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        $0.backgroundColor = .systemBlue
        $0.setTitleColor(.white, for: .normal)
        $0.layer.cornerRadius = 8
        $0.isEnabled = false
        $0.alpha = 0.5
    }
    
    // MARK: - Initialization
    
    /**
     * 초기화자
     * @param videoURL 비디오 파일 URL
     * @param completion 썸네일 선택 완료 콜백
     */
    init(videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        self.videoURL = videoURL
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateThumbnails()
    }
    
    /**
     * 화면 회전 시 컬렉션뷰 레이아웃 업데이트
     * 다이나믹 아일랜드 대응 레이아웃 업데이트
     */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            // 화면 회전 중 컬렉션뷰 레이아웃 무효화
            self.collectionView.collectionViewLayout.invalidateLayout()
            
            // 다이나믹 아일랜드 대응 레이아웃 업데이트
            self.updateLayoutForOrientation()
        }, completion: { _ in
            // 회전 완료 후 레이아웃 강제 업데이트
            self.collectionView.reloadData()
        })
    }
    
    // MARK: - Dynamic Island Support
    
    /**
     * 화면 회전 시 레이아웃 업데이트
     */
    private func updateLayoutForOrientation() {
        // 가로/세로 모드에 따른 여백 조정
        let isLandscape = view.frame.width > view.frame.height
        let horizontalInset: CGFloat = isLandscape ? 40 : 20
        let topOffset: CGFloat = isLandscape ? 10 : 20
        
        titleLabel.snp.updateConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(topOffset)
            $0.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        
        descriptionLabel.snp.updateConstraints {
            $0.leading.trailing.equalToSuperview().inset(horizontalInset)
        }
        
        cancelButton.snp.updateConstraints {
            $0.leading.equalToSuperview().offset(horizontalInset)
        }
        
        confirmButton.snp.updateConstraints {
            $0.trailing.equalToSuperview().offset(-horizontalInset)
        }
        
        view.layoutIfNeeded()
    }
    
    // MARK: - Setup
    
    /**
     * UI 구성 및 레이아웃 설정
     */
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // 서브뷰 추가
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(buttonContainer)
        buttonContainer.addSubview(cancelButton)
        buttonContainer.addSubview(confirmButton)
        
        // 레이아웃 설정
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(8)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        collectionView.snp.makeConstraints {
            $0.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(buttonContainer.snp.top)
        }
        
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(collectionView)
        }
        
        buttonContainer.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(80)
        }
        
        cancelButton.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(20)
            $0.top.equalToSuperview().offset(16)
            $0.height.equalTo(48)
            $0.width.equalTo(80)
        }
        
        confirmButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-20)
            $0.top.equalToSuperview().offset(16)
            $0.height.equalTo(48)
            $0.leading.equalTo(cancelButton.snp.trailing).offset(16)
        }
        
        // 버튼 액션 설정
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
    }
    
    // MARK: - Thumbnail Generation
    
    /**
     * 여러 시점에서 썸네일 생성
     */
    private func generateThumbnails() {
        loadingIndicator.startAnimating()
        thumbnailImages = Array(repeating: nil, count: timeStamps.count)
        
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 200, height: 200)
        
        let duration = asset.duration.seconds
        let validTimeStamps = timeStamps.filter { $0 < duration }
        
        let group = DispatchGroup()
        
        for (index, timeStamp) in validTimeStamps.enumerated() {
            group.enter()
            
            let time = CMTime(seconds: timeStamp, preferredTimescale: 600)
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] _, cgImage, _, _, _ in
                defer { group.leave() }
                
                if let cgImage = cgImage {
                    let image = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.thumbnailImages[index] = image
                        self?.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                    }
                }
            }
        }
        
        group.notify(queue: .main) { [weak self] in
            self?.loadingIndicator.stopAnimating()
        }
    }
    
    // MARK: - Actions
    
    /**
     * 취소 버튼 액션
     */
    @objc private func cancelButtonTapped() {
        dismiss(animated: true) { [weak self] in
            self?.completion(nil)
        }
    }
    
    /**
     * 확인 버튼 액션
     */
    @objc private func confirmButtonTapped() {
        guard let selectedIndex = selectedIndex,
              let selectedImage = thumbnailImages[selectedIndex] else {
            return
        }
        
        // 선택된 썸네일을 캐시에 저장
        ThumbnailCacheManager.shared.saveThumbnail(selectedImage, for: videoURL)
        
        dismiss(animated: true) { [weak self] in
            self?.completion(selectedImage)
        }
    }
    
    /**
     * 확인 버튼 상태 업데이트
     */
    private func updateConfirmButton() {
        let isEnabled = selectedIndex != nil
        confirmButton.isEnabled = isEnabled
        confirmButton.alpha = isEnabled ? 1.0 : 0.5
    }
}

// MARK: - UICollectionViewDataSource

extension ThumbnailSelectionViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return timeStamps.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ThumbnailCell.identifier, for: indexPath) as! ThumbnailCell
        
        let timeStamp = timeStamps[indexPath.item]
        let image = thumbnailImages[indexPath.item]
        let isSelected = selectedIndex == indexPath.item
        
        cell.configure(image: image, timeStamp: timeStamp, isSelected: isSelected)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ThumbnailSelectionViewController: UICollectionViewDelegateFlowLayout {
    
    /**
     * 셀 크기를 동적으로 계산
     * 가로/세로 모드에 따라 적절한 크기 반환
     */
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let padding = layout.sectionInset.left + layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        
        // 가로/세로 모드에 따라 열 수 조정
        let isLandscape = view.frame.width > view.frame.height
        let numberOfColumns: CGFloat = isLandscape ? 4 : 2 // 가로 모드에서 4열, 세로 모드에서 2열
        
        let availableWidth = collectionView.frame.width - padding - (spacing * (numberOfColumns - 1))
        let itemWidth = max(availableWidth / numberOfColumns, 80) // 최소 크기 보장
        
        // 16:9 비율 유지
        let itemHeight = itemWidth * 9 / 16
        
        return CGSize(width: itemWidth, height: itemHeight)
    }
}

// MARK: - UICollectionViewDelegate

extension ThumbnailSelectionViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // 이전 선택 해제
        if let previousIndex = selectedIndex {
            collectionView.reloadItems(at: [IndexPath(item: previousIndex, section: 0)])
        }
        
        // 새로운 선택 설정
        selectedIndex = indexPath.item
        collectionView.reloadItems(at: [indexPath])
        
        updateConfirmButton()
    }
}



// MARK: - ThumbnailCell

/**
 * 썸네일 컬렉션 뷰 셀
 */
class ThumbnailCell: UICollectionViewCell {
    
    static let identifier = "ThumbnailCell"
    
    // MARK: - UI Components
    
    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 8
        $0.backgroundColor = .systemGray5
    }
    
    private let timeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 12)
        $0.textColor = .systemGray
        $0.textAlignment = .center
    }
    
    private let loadingIndicator = UIActivityIndicatorView(style: .medium).then {
        $0.hidesWhenStopped = true
    }
    
    private let selectionOverlay = UIView().then {
        $0.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        $0.layer.cornerRadius = 8
        $0.isHidden = true
    }
    
    private let checkmarkImageView = UIImageView().then {
        $0.image = UIImage(systemName: "checkmark.circle.fill")
        $0.tintColor = .systemBlue
        $0.backgroundColor = .white
        $0.layer.cornerRadius = 12
        $0.isHidden = true
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(imageView)
        addSubview(timeLabel)
        addSubview(loadingIndicator)
        addSubview(selectionOverlay)
        addSubview(checkmarkImageView)
        
        // 이미지뷰 - 16:9 비율 유지하면서 유연한 크기 조정
        imageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(timeLabel.snp.top).offset(-4)
        }
        
        // 시간 레이블 - 하단 고정
        timeLabel.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview()
            $0.height.equalTo(20)
        }
        
        // 로딩 인디케이터 - 이미지뷰 중앙
        loadingIndicator.snp.makeConstraints {
            $0.center.equalTo(imageView)
        }
        
        // 선택 오버레이 - 이미지뷰와 같은 크기
        selectionOverlay.snp.makeConstraints {
            $0.edges.equalTo(imageView)
        }
        
        // 체크마크 - 우상단 고정
        checkmarkImageView.snp.makeConstraints {
            $0.top.trailing.equalTo(imageView).inset(6)
            $0.width.height.equalTo(20)
        }
    }
    
    // MARK: - Configuration
    
    func configure(image: UIImage?, timeStamp: Double, isSelected: Bool) {
        if let image = image {
            imageView.image = image
            loadingIndicator.stopAnimating()
        } else {
            imageView.image = nil
            loadingIndicator.startAnimating()
        }
        
        timeLabel.text = formatTime(timeStamp)
        
        selectionOverlay.isHidden = !isSelected
        checkmarkImageView.isHidden = !isSelected
    }
    
    private func formatTime(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, remainingSeconds)
    }
} 
