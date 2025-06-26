//
//  VideoModel.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/11/25.
//

import Foundation

/**
 * 비디오 파일의 메타데이터를 담는 모델 구조체
 * - 파일 URL, 이름, 크기, 생성일, 재생시간 등의 정보 포함
 * - 파일 시스템에서 비디오 속성을 자동으로 읽어옴
 * - 사용자 정의 이름을 UserDefaults에 영구 저장
 */
struct VideoModel {
    /// 비디오 파일의 로컬 URL
    let url: URL
    
    /// 원본 비디오 파일명 (확장자 포함)
    private let originalName: String
    
    /// 파일 크기 (바이트 단위, 읽기 실패 시 nil)
    let fileSize: Int64?
    
    /// 파일 생성 날짜 (읽기 실패 시 nil)
    let createdDate: Date?
    
    /// 비디오 재생 시간 (현재 미구현, 필요시 AVAsset 사용)
    let duration: TimeInterval?
    
    /// 비디오 파일의 고유 식별자 (URL path 기반)
    var filePath: String {
        return url.path
    }
    
    /// 표시될 비디오 이름 (사용자 정의 이름이 있으면 그것을, 없으면 원본 파일명)
    var name: String {
        get {
            return VideoNameManager.shared.getCustomName(for: filePath) ?? originalName
        }
        set {
            VideoNameManager.shared.setCustomName(newValue, for: filePath)
        }
    }
    
    /**
     * URL로부터 비디오 모델 초기화
     * 파일 시스템에서 메타데이터를 자동으로 읽어와 설정
     * @param url 비디오 파일의 로컬 URL
     */
    init(url: URL) {
        self.url = url
        self.originalName = url.lastPathComponent
        
        // 파일 속성 읽기 (크기, 생성일)
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
        self.fileSize = resourceValues?.fileSize.map { Int64($0) }
        self.createdDate = resourceValues?.creationDate
        self.duration = nil // TODO: AVAsset을 사용하여 실제 재생시간 구현
    }
    
    /**
     * 파일 크기를 사람이 읽기 쉬운 형태로 포맷팅
     * @return "1.5 MB", "500 KB" 등의 형태로 포맷된 문자열
     */
    var formattedFileSize: String {
        guard let fileSize = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
    
    /**
     * 생성 날짜를 사람이 읽기 쉬운 형태로 포맷팅
     * @return "2025년 1월 15일 오후 3:45" 등의 형태로 포맷된 문자열
     */
    var formattedCreatedDate: String {
        guard let createdDate = createdDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
}

// MARK: - Video Save Progress

/**
 * 비디오 파일 저장 진행률 정보를 담는 구조체
 * UI에서 진행률 표시에 사용
 */
struct VideoSaveProgress {
    /// 전체 파일 크기 (바이트)
    let totalBytes: Int64
    
    /// 현재까지 복사된 크기 (바이트)
    let copiedBytes: Int64
    
    /// 진행률 (0.0 ~ 1.0)
    let progress: Double
    
    /// 저장 완료 여부 (진행률이 100%인지 확인)
    var isCompleted: Bool {
        return progress >= 1.0
    }
}

// MARK: - Video Service Protocol

/**
 * 비디오 파일 관리를 위한 서비스 프로토콜
 * - 비디오 로드, 저장, 삭제 기능 정의
 * - 테스트 가능성을 위한 프로토콜 기반 설계
 */
protocol VideoServiceProtocol {
    /**
     * 저장된 비디오 목록 로드
     * @param completion 로드 완료 시 호출되는 클로저 (성공/실패 결과 포함)
     */
    func loadVideos(completion: @escaping (Result<[VideoModel], Error>) -> Void)
    
    /**
     * 새로운 비디오 파일 저장
     * @param sourceURL 원본 비디오 파일 URL
     * @param progressHandler 저장 진행률 업데이트 클로저 (옵셔널)
     * @param completion 저장 완료 시 호출되는 클로저 (성공/실패 결과 포함)
     */
    func saveVideo(_ sourceURL: URL, 
                  progressHandler: ((VideoSaveProgress) -> Void)?,
                  completion: @escaping (Result<VideoModel, Error>) -> Void)
    
    /**
     * 비디오 파일 삭제
     * @param video 삭제할 비디오 모델
     * @param completion 삭제 완료 시 호출되는 클로저 (성공/실패 결과 포함)
     */
    func deleteVideo(_ video: VideoModel, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Video Service Implementation

/**
 * 비디오 파일 관리 서비스 구현체
 * - Documents/Videos 디렉토리에 파일 저장/관리
 * - 백그라운드 큐에서 파일 작업 수행
 * - 진행률 추적을 포함한 파일 복사
 */
class VideoService: VideoServiceProtocol {
    
    /// 파일 시스템 접근을 위한 FileManager 인스턴스
    private let fileManager = FileManager.default
    
    /// 앱의 Documents 디렉토리 URL
    private var documentsDirectory: URL? {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
    }
    
    // MARK: - Videos Directory
    
    /// 비디오 파일들이 저장되는 디렉토리 URL (Documents/Videos)
    private var videosDirectory: URL? {
        guard let documentsDirectory = documentsDirectory else { return nil }
        let videosDir = documentsDirectory.appendingPathComponent("Videos")
        
        // Videos 디렉토리가 없으면 생성
        if !fileManager.fileExists(atPath: videosDir.path) {
            try? fileManager.createDirectory(at: videosDir, withIntermediateDirectories: true)
        }
        
        return videosDir
    }
    
    /**
     * Videos 디렉토리에서 비디오 파일 목록을 로드
     * 백그라운드 큐에서 실행되며 완료 시 메인 큐에서 콜백 호출
     * @param completion 로드 완료 시 호출되는 클로저
     */
    func loadVideos(completion: @escaping (Result<[VideoModel], Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let videosDirectory = self.videosDirectory else {
                DispatchQueue.main.async {
                    completion(.failure(VideoServiceError.documentDirectoryNotFound))
                }
                return
            }
            
            do {
                // 디렉토리 내 모든 파일 URL 가져오기 (메타데이터 포함)
                let fileURLs = try self.fileManager.contentsOfDirectory(
                    at: videosDirectory,
                    includingPropertiesForKeys: [.fileSizeKey, .creationDateKey]
                )
                
                // 지원되는 비디오 확장자 필터링
                let videoURLs = fileURLs.filter { 
                    ["mov", "mp4", "avi", "mkv", "m4v", "3gp"].contains($0.pathExtension.lowercased()) 
                }
                
                // URL을 VideoModel로 변환
                let videos = videoURLs.map { VideoModel(url: $0) }
                
                DispatchQueue.main.async {
                    completion(.success(videos))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveVideo(_ sourceURL: URL, 
                  progressHandler: ((VideoSaveProgress) -> Void)? = nil,
                  completion: @escaping (Result<VideoModel, Error>) -> Void) {
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self,
                  let videosDirectory = self.videosDirectory else {
                DispatchQueue.main.async {
                    completion(.failure(VideoServiceError.documentDirectoryNotFound))
                }
                return
            }
            
            do {
                // 파일 크기 확인
                let resourceValues = try sourceURL.resourceValues(forKeys: [.fileSizeKey])
                let totalFileSize = Int64(resourceValues.fileSize ?? 0)
                
                // 고유한 파일명 생성
                let uniqueFileName = self.generateUniqueFileName(for: sourceURL, in: videosDirectory)
                let destinationURL = videosDirectory.appendingPathComponent(uniqueFileName)
                
                // 파일 복사 시작
                DispatchQueue.main.async {
                    progressHandler?(VideoSaveProgress(totalBytes: totalFileSize, copiedBytes: 0, progress: 0.0))
                }
                
                // 파일 복사 (진행률과 함께)
                try self.copyFileWithProgress(
                    from: sourceURL,
                    to: destinationURL,
                    totalSize: totalFileSize,
                    progressHandler: progressHandler
                )
                
                let video = VideoModel(url: destinationURL)
                
                DispatchQueue.main.async {
                    progressHandler?(VideoSaveProgress(totalBytes: totalFileSize, copiedBytes: totalFileSize, progress: 1.0))
                    completion(.success(video))
                }
                
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteVideo(_ video: VideoModel, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.fileManager.removeItem(at: video.url)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Private Helper Methods
    private func generateUniqueFileName(for sourceURL: URL, in directory: URL) -> String {
        let originalName = sourceURL.deletingPathExtension().lastPathComponent
        let fileExtension = sourceURL.pathExtension
        
        var fileName = "\(originalName).\(fileExtension)"
        var counter = 1
        
        while fileManager.fileExists(atPath: directory.appendingPathComponent(fileName).path) {
            fileName = "\(originalName)_\(counter).\(fileExtension)"
            counter += 1
        }
        
        return fileName
    }
    
    private func copyFileWithProgress(from sourceURL: URL, 
                                    to destinationURL: URL, 
                                    totalSize: Int64,
                                    progressHandler: ((VideoSaveProgress) -> Void)?) throws {
        
        let bufferSize = 64 * 1024 // 64KB 버퍼
        
        guard let inputStream = InputStream(url: sourceURL),
              let outputStream = OutputStream(url: destinationURL, append: false) else {
            throw VideoServiceError.fileStreamError
        }
        
        inputStream.open()
        outputStream.open()
        
        defer {
            inputStream.close()
            outputStream.close()
        }
        
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        
        var totalCopied: Int64 = 0
        
        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(buffer, maxLength: bufferSize)
            
            if bytesRead < 0 {
                throw inputStream.streamError ?? VideoServiceError.fileReadError
            }
            
            if bytesRead == 0 {
                break
            }
            
            let bytesWritten = outputStream.write(buffer, maxLength: bytesRead)
            
            if bytesWritten < 0 {
                throw outputStream.streamError ?? VideoServiceError.fileWriteError
            }
            
            totalCopied += Int64(bytesWritten)
            
            // 진행률 업데이트
            let progress = totalSize > 0 ? Double(totalCopied) / Double(totalSize) : 0.0
            DispatchQueue.main.async {
                progressHandler?(VideoSaveProgress(totalBytes: totalSize, copiedBytes: totalCopied, progress: progress))
            }
        }
    }
}

// MARK: - Video Service Error
enum VideoServiceError: LocalizedError {
    case documentDirectoryNotFound
    case fileAlreadyExists
    case fileStreamError
    case fileReadError
    case fileWriteError
    case insufficientStorage
    
    var errorDescription: String? {
        switch self {
        case .documentDirectoryNotFound:
            return "문서 디렉토리를 찾을 수 없습니다"
        case .fileAlreadyExists:
            return "이미 존재하는 파일입니다"
        case .fileStreamError:
            return "파일 스트림 생성에 실패했습니다"
        case .fileReadError:
            return "파일 읽기에 실패했습니다"
        case .fileWriteError:
            return "파일 쓰기에 실패했습니다"
        case .insufficientStorage:
            return "저장 공간이 부족합니다"
        }
    }
}

// MARK: - VideoNameManager

/**
 * 비디오 파일의 사용자 정의 이름을 관리하는 매니저
 * UserDefaults를 사용하여 파일별 커스텀 이름을 영구 저장
 */
class VideoNameManager {
    /// 싱글톤 인스턴스
    static let shared = VideoNameManager()
    
    /// UserDefaults 키 prefix
    private let keyPrefix = "VideoCustomName_"
    
    /// UserDefaults 인스턴스
    private let userDefaults = UserDefaults.standard
    
    private init() {}
    
    /**
     * 파일의 사용자 정의 이름을 가져옴
     * @param fileIdentifier 파일 고유 식별자 (URL path)
     * @return 저장된 사용자 정의 이름 (없으면 nil)
     */
    func getCustomName(for fileIdentifier: String) -> String? {
        let key = keyPrefix + fileIdentifier
        return userDefaults.string(forKey: key)
    }
    
    /**
     * 파일의 사용자 정의 이름을 저장
     * @param customName 저장할 사용자 정의 이름
     * @param fileIdentifier 파일 고유 식별자 (URL path)
     */
    func setCustomName(_ customName: String, for fileIdentifier: String) {
        let key = keyPrefix + fileIdentifier
        let trimmedName = customName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            // 빈 문자열이면 사용자 정의 이름 삭제
            removeCustomName(for: fileIdentifier)
        } else {
            userDefaults.set(trimmedName, forKey: key)
        }
    }
    
    /**
     * 파일의 사용자 정의 이름을 삭제 (원본 이름으로 되돌림)
     * @param fileIdentifier 파일 고유 식별자 (URL path)
     */
    func removeCustomName(for fileIdentifier: String) {
        let key = keyPrefix + fileIdentifier
        userDefaults.removeObject(forKey: key)
    }
    
    /**
     * 모든 사용자 정의 이름을 삭제 (디버그용)
     */
    func clearAllCustomNames() {
        let keys = userDefaults.dictionaryRepresentation().keys
        for key in keys {
            if key.hasPrefix(keyPrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
    }
    
    /**
     * 모든 사용자 정의 이름 가져오기 (마이그레이션용)
     * @return [파일경로: 사용자정의이름] 딕셔너리
     */
    func getAllCustomNames() -> [String: String] {
        var customNames: [String: String] = [:]
        let keys = userDefaults.dictionaryRepresentation().keys
        
        for key in keys {
            if key.hasPrefix(keyPrefix),
               let customName = userDefaults.string(forKey: key) {
                let filePath = String(key.dropFirst(keyPrefix.count))
                customNames[filePath] = customName
            }
        }
        
        return customNames
    }
}
