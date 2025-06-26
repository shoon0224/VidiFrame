//
//  VideoListViewModel.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/11/25.
//

import Foundation

// MARK: - VideoListViewModelProtocol

/**
 * 비디오 목록 관리를 위한 뷰모델 프로토콜
 * - MVVM 패턴의 뷰모델 역할 정의
 * - UI와 비즈니스 로직 분리를 위한 인터페이스 제공
 * - 테스트 가능성을 위한 프로토콜 기반 설계
 */
protocol VideoListViewModelProtocol {
    // MARK: - Properties
    
    /// 현재 로드된 비디오 목록
    var videos: [VideoModel] { get }
    
    /// 현재 로딩 상태 (true: 로딩 중, false: 완료)
    var isLoading: Bool { get }
    
    /// 최근 발생한 에러 메시지 (에러가 없으면 nil)
    var errorMessage: String? { get }
    
    // MARK: - Callbacks
    
    /// 비디오 목록이 업데이트될 때 호출되는 클로저
    var onVideosUpdated: (() -> Void)? { get set }
    
    /// 로딩 상태가 변경될 때 호출되는 클로저
    var onLoadingStateChanged: ((Bool) -> Void)? { get set }
    
    /// 에러가 발생했을 때 호출되는 클로저
    var onError: ((String) -> Void)? { get set }
    
    /// 파일 저장 진행률 업데이트 시 호출되는 클로저
    var onSaveProgress: ((VideoSaveProgress) -> Void)? { get set }
    
    // MARK: - Methods
    
    /// 저장된 비디오 목록을 로드
    func loadVideos()
    
    /// 새로운 비디오 파일을 추가
    func addVideo(_ sourceURL: URL)
    
    /// 지정된 인덱스의 비디오를 삭제
    func deleteVideo(at index: Int)
    
    /// 지정된 인덱스의 비디오 이름을 변경
    func renameVideo(at index: Int, newName: String)
    
    /// 비디오 개수를 반환
    func numberOfVideos() -> Int
    
    /// 지정된 인덱스의 비디오 모델을 반환
    func video(at index: Int) -> VideoModel?
    
    // MARK: - Convenience Methods
    
    /// 지정된 인덱스의 비디오 파일명을 반환
    func videoName(at index: Int) -> String
    
    /// 지정된 인덱스의 비디오 파일 크기를 반환
    func videoFileSize(at index: Int) -> String
    
    /// 지정된 인덱스의 비디오 생성 날짜를 반환
    func videoCreatedDate(at index: Int) -> String
    
    /// 지정된 인덱스의 비디오 URL을 반환
    func videoURL(at index: Int) -> URL?
}

// MARK: - VideoListViewModel

/**
 * 비디오 목록 관리를 위한 뷰모델 구현체
 * - VideoListViewModelProtocol을 구현
 * - 비디오 서비스와 UI 사이의 중간 계층 역할
 * - 상태 관리 및 UI 업데이트 콜백 제공
 */
class VideoListViewModel: VideoListViewModelProtocol {
    
    // MARK: - Properties
    
    /// 현재 로드된 비디오 목록 (변경 시 onVideosUpdated 콜백 호출)
    private(set) var videos: [VideoModel] = [] {
        didSet {
            onVideosUpdated?()
        }
    }
    
    /// 현재 로딩 상태 (변경 시 onLoadingStateChanged 콜백 호출)
    private(set) var isLoading: Bool = false {
        didSet {
            onLoadingStateChanged?(isLoading)
        }
    }
    
    /// 에러 메시지 (설정 시 onError 콜백 호출)
    private(set) var errorMessage: String? {
        didSet {
            if let errorMessage = errorMessage {
                onError?(errorMessage)
            }
        }
    }
    
    // MARK: - Dependencies
    
    /// 비디오 파일 관리를 담당하는 서비스 (의존성 주입 가능)
    private let videoService: VideoServiceProtocol
    
    // MARK: - Callbacks
    
    /// 비디오 목록 업데이트 시 호출되는 클로저
    var onVideosUpdated: (() -> Void)?
    
    /// 로딩 상태 변경 시 호출되는 클로저
    var onLoadingStateChanged: ((Bool) -> Void)?
    
    /// 에러 발생 시 호출되는 클로저
    var onError: ((String) -> Void)?
    
    /// 파일 저장 진행률 업데이트 시 호출되는 클로저
    var onSaveProgress: ((VideoSaveProgress) -> Void)?
    
    // MARK: - Initialization
    
    /**
     * 뷰모델 초기화
     * @param videoService 비디오 관리 서비스 (기본값: VideoService())
     */
    init(videoService: VideoServiceProtocol = VideoService()) {
        self.videoService = videoService
    }
    
    // MARK: - Public Methods
    
    /**
     * 저장된 비디오 목록을 로드
     * 로딩 상태를 관리하고 결과에 따라 videos 배열 업데이트
     */
    func loadVideos() {
        isLoading = true
        errorMessage = nil
        
        videoService.loadVideos { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let videos):
                // 생성 날짜 기준으로 내림차순 정렬 (최신 파일이 위에)
                self.videos = videos.sorted { $0.createdDate ?? Date.distantPast > $1.createdDate ?? Date.distantPast }
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.videos = []
            }
        }
    }
    
    /**
     * 새로운 비디오 파일을 추가
     * 원본 파일을 앱 내부 디렉토리로 복사하고 진행률 추적
     * @param sourceURL 추가할 원본 비디오 파일의 URL
     */
    func addVideo(_ sourceURL: URL) {
        isLoading = true
        errorMessage = nil
        
        videoService.saveVideo(sourceURL, progressHandler: { [weak self] progress in
            self?.onSaveProgress?(progress)
        }) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success(let video):
                self.videos.insert(video, at: 0) // 새 비디오를 맨 위에 추가
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /**
     * 지정된 인덱스의 비디오를 삭제
     * 파일 시스템에서 실제 파일도 함께 삭제
     * @param index 삭제할 비디오의 인덱스
     */
    func deleteVideo(at index: Int) {
        guard index < videos.count else { return }
        
        let video = videos[index]
        isLoading = true
        errorMessage = nil
        
        videoService.deleteVideo(video) { [weak self] result in
            guard let self = self else { return }
            
            self.isLoading = false
            
            switch result {
            case .success:
                self.videos.remove(at: index)
            case .failure(let error):
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    /**
     * 지정된 인덱스의 비디오 이름을 변경
     * UserDefaults에 영구 저장되어 앱 재시작 후에도 유지됨
     * @param index 이름을 변경할 비디오의 인덱스
     * @param newName 새로운 비디오 이름
     */
    func renameVideo(at index: Int, newName: String) {
        guard index < videos.count else { return }
        
        // 이름 유효성 검사
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // UserDefaults에 커스텀 이름 저장
        VideoNameManager.shared.setCustomName(trimmedName, for: videos[index].filePath)
        
        // UI 모델만 업데이트 (실제로는 VideoModel의 name getter에서 UserDefaults에서 가져옴)
        
        // UI 업데이트를 위한 콜백 호출
        onVideosUpdated?()
    }
    
    /**
     * 현재 비디오 개수 반환
     * @return 비디오 배열의 크기
     */
    func numberOfVideos() -> Int {
        return videos.count
    }
    
    /**
     * 지정된 인덱스의 비디오 모델 반환
     * @param index 가져올 비디오의 인덱스
     * @return 해당 인덱스의 VideoModel (범위를 벗어나면 nil)
     */
    func video(at index: Int) -> VideoModel? {
        guard index < videos.count else { return nil }
        return videos[index]
    }
}

// MARK: - Convenience Methods

/**
 * 편의 메서드들을 제공하는 VideoListViewModel 확장
 * UI에서 자주 사용되는 비디오 정보 접근을 단순화
 */
extension VideoListViewModel {
    
    /**
     * 지정된 인덱스의 비디오 파일명 반환
     * @param index 비디오 인덱스
     * @return 파일명 (찾을 수 없으면 "Unnamed")
     */
    func videoName(at index: Int) -> String {
        return video(at: index)?.name ?? "Unnamed"
    }
    
    /**
     * 지정된 인덱스의 비디오 파일 크기 반환 (포맷된 문자열)
     * @param index 비디오 인덱스
     * @return 파일 크기 문자열 (찾을 수 없으면 "Unknown")
     */
    func videoFileSize(at index: Int) -> String {
        return video(at: index)?.formattedFileSize ?? "Unknown"
    }
    
    /**
     * 지정된 인덱스의 비디오 생성 날짜 반환 (포맷된 문자열)
     * @param index 비디오 인덱스
     * @return 생성 날짜 문자열 (찾을 수 없으면 "Unknown")
     */
    func videoCreatedDate(at index: Int) -> String {
        return video(at: index)?.formattedCreatedDate ?? "Unknown"
    }
    
    /**
     * 지정된 인덱스의 비디오 파일 URL 반환
     * @param index 비디오 인덱스
     * @return 파일 URL (찾을 수 없으면 nil)
     */
    func videoURL(at index: Int) -> URL? {
        return video(at: index)?.url
    }
}
