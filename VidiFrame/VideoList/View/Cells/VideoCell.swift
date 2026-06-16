//
//  VideoCell.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/11/25.
//

import UIKit
import AVFoundation

/**
 * 비디오 목록에서 각 비디오 항목을 표시하는 테이블뷰 셀
 * - 썸네일 이미지, 재생 아이콘, 제목, 파일 크기, 생성 날짜 표시
 * - 재사용 가능한 셀로 설계
 */
class VideoCell: UITableViewCell {
    
    /// 셀 재사용 식별자
    static let identifier = "VideoCell"

    // MARK: - UI Components
    
    private let glassBackgroundView = LiquidGlassContainerView(
        cornerRadius: 16,
        style: .regular,
        presence: .elevated
    )
    
    /// 비디오 썸네일 이미지뷰 (둥근 모서리, 기본 비디오 아이콘 표시)
    private let thumbnailImageView = UIImageView().then {
        $0.backgroundColor = UIColor.secondarySystemFill.withAlphaComponent(0.5)
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = 10
        $0.layer.cornerCurve = .continuous
        $0.image = UIImage(systemName: "video.fill")
        $0.tintColor = .tertiaryLabel
    }
    
    /// 비디오 파일명을 표시하는 제목 레이블 (최대 2줄)
    private let titleLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 16, weight: .semibold)
        $0.textColor = .label
        $0.numberOfLines = 2
    }
    
    /// 파일 크기를 표시하는 레이블
    private let fileSizeLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }
    
    /// 파일 생성 날짜를 표시하는 레이블
    private let dateLabel = UILabel().then {
        $0.font = .systemFont(ofSize: 13, weight: .regular)
        $0.textColor = .secondaryLabel
    }
    
    /// 제목과 정보를 세로로 배치하는 메인 스택뷰
    private let stackView = UIStackView().then {
        $0.axis = .vertical
        $0.spacing = 4
        $0.alignment = .leading
    }
    
    /// 파일 크기와 날짜를 가로로 배치하는 정보 스택뷰
    private let infoStackView = UIStackView().then {
        $0.axis = .horizontal
        $0.spacing = 12
        $0.distribution = .fillEqually
    }
    
    /// 현재 셀에 표시 중인 비디오 URL (셀 재사용 시 썸네일 로딩 충돌 방지용)
    private var currentVideoURL: URL?
    
    /// 옵션 버튼 (세로 점 3개)
    private let optionsButton = UIButton(type: .system).then {
        $0.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        $0.tintColor = .secondaryLabel
        $0.backgroundColor = .clear
    }
    
    /// 옵션 버튼 콜백 클로저
    var onOptionsButtonTapped: (() -> Void)?

    // MARK: - Initialization
    
    /**
     * @param style 셀 스타일
     * @param reuseIdentifier 재사용 식별자
     */
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup
    
    /**
     * UI 요소들의 레이아웃과 스타일 설정
     * 스택뷰 구성 및 Auto Layout 제약 조건 설정
     */
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        infoStackView.addArrangedSubview(fileSizeLabel)
        infoStackView.addArrangedSubview(dateLabel)
        
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(infoStackView)
        
        contentView.addSubview(glassBackgroundView)
        glassBackgroundView.contentView.addSubview(thumbnailImageView)
        glassBackgroundView.contentView.addSubview(stackView)
        glassBackgroundView.contentView.addSubview(optionsButton)
        
        optionsButton.addTarget(self, action: #selector(optionsButtonTapped), for: .touchUpInside)
        
        glassBackgroundView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(5)
            $0.bottom.equalToSuperview().offset(-5)
            $0.leading.trailing.equalToSuperview().inset(20)
        }
        
        thumbnailImageView.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(14)
            $0.top.greaterThanOrEqualToSuperview().offset(12)
            $0.bottom.lessThanOrEqualToSuperview().offset(-12)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(60)
        }
        
        optionsButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-14)
            $0.centerY.equalToSuperview()
            $0.width.height.equalTo(32)
        }
        
        stackView.snp.makeConstraints {
            $0.leading.equalTo(thumbnailImageView.snp.trailing).offset(12)
            $0.trailing.equalTo(optionsButton.snp.leading).offset(-12)
            $0.centerY.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview().offset(8)
            $0.bottom.lessThanOrEqualToSuperview().offset(-8)
        }
    }
    
    // MARK: - Configuration
    
    /**
     * 비디오 모델 데이터로 셀 구성
     * @param video 표시할 비디오 모델 데이터
     */
    func configure(with video: VideoModel) {
        titleLabel.text = video.name
        fileSizeLabel.text = video.formattedFileSize
        dateLabel.text = video.formattedCreatedDate
        
        currentVideoURL = video.url
        
        thumbnailImageView.image = UIImage(systemName: "video.fill")
        loadThumbnail(for: video.url)
    }
    
    /**
     * 제목만으로 셀 구성 (간단한 표시용)
     * @param title 표시할 제목
     */
    func configure(title: String) {
        titleLabel.text = title
        fileSizeLabel.text = ""
        dateLabel.text = ""
    }
    
    // MARK: - Actions
    
    /**
     * 옵션 버튼 탭 액션
     * 외부에서 설정한 콜백 클로저 실행
     */
    @objc private func optionsButtonTapped() {
        onOptionsButtonTapped?()
    }
    
    // MARK: - Private Methods
    
    /**
     * 비디오 URL로부터 썸네일 이미지 로드
     * ThumbnailCacheManager를 사용하여 캐싱된 썸네일 로드 또는 생성
     * @param url 비디오 파일 URL
     */
    private func loadThumbnail(for url: URL) {
        ThumbnailCacheManager.shared.getThumbnail(for: url) { [weak self] thumbnailImage in
            guard let self = self else { return }
            
            if let currentURL = self.currentVideoURL, currentURL == url {
                if let thumbnailImage = thumbnailImage {
                    self.thumbnailImageView.image = thumbnailImage
                } else {
                    self.thumbnailImageView.image = UIImage(systemName: "video.fill")
                }
            }
        }
    }
    
    // MARK: - Reuse
    
    /**
     * 셀 재사용 시 호출되어 이전 데이터 초기화
     * 메모리 누수 방지 및 올바른 데이터 표시를 위해 필수
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        
        currentVideoURL = nil
        onOptionsButtonTapped = nil
        
        thumbnailImageView.image = UIImage(systemName: "video.fill")
        titleLabel.text = nil
        fileSizeLabel.text = nil
        dateLabel.text = nil
    }
}
