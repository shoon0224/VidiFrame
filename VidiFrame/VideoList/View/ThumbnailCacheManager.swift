//
//  ThumbnailCacheManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import AVFoundation

/**
 * 비디오 썸네일 캐싱 및 생성을 관리하는 싱글톤 클래스
 * - 메모리 캐시와 디스크 캐시를 활용하여 성능 최적화
 * - AVAssetImageGenerator를 사용한 썸네일 생성
 * - 백그라운드에서 비동기 처리
 */
class ThumbnailCacheManager {
    
    /// 싱글톤 인스턴스
    static let shared = ThumbnailCacheManager()
    
    /// 메모리 캐시 (NSCache 사용)
    private let memoryCache = NSCache<NSString, UIImage>()
    
    /// 캐시 디렉토리 URL
    private let cacheDirectory: URL
    
    /// 파일 매니저
    private let fileManager = FileManager.default
    
    /// 썸네일 생성 큐 (동시 실행 제한)
    private let thumbnailQueue = DispatchQueue(label: "thumbnail.generation", qos: .userInitiated, attributes: .concurrent)
    
    // MARK: - Initialization
    
    /**
     * 프라이빗 초기화자 (싱글톤 패턴)
     * 캐시 디렉토리 설정 및 메모리 캐시 구성
     */
    private init() {
        // 캐시 디렉토리 설정 (Documents/Thumbnails)
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        cacheDirectory = documentsPath.appendingPathComponent("Thumbnails")
        
        // 캐시 디렉토리 생성
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        
        // 메모리 캐시 설정 (최대 50개 썸네일)
        memoryCache.countLimit = 50
        
        // 메모리 경고 시 캐시 정리
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemoryCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Public Methods
    
    /**
     * 비디오 URL로부터 썸네일 이미지를 가져오거나 생성
     * @param videoURL 비디오 파일 URL
     * @param completion 썸네일 로드 완료 시 호출되는 클로저
     */
    func getThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        let cacheKey = cacheKey(for: videoURL)
        
        // 1. 메모리 캐시에서 확인
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            completion(cachedImage)
            return
        }
        
        // 2. 디스크 캐시에서 확인
        let diskCachePath = diskCachePath(for: videoURL)
        if fileManager.fileExists(atPath: diskCachePath.path),
           let cachedImage = UIImage(contentsOfFile: diskCachePath.path) {
            // 메모리 캐시에도 저장
            memoryCache.setObject(cachedImage, forKey: cacheKey)
            completion(cachedImage)
            return
        }
        
        // 3. 썸네일 생성
        generateThumbnail(for: videoURL) { [weak self] image in
            guard let self = self, let image = image else {
                completion(nil)
                return
            }
            
            // 메모리 캐시에 저장
            self.memoryCache.setObject(image, forKey: cacheKey)
            
            // 디스크 캐시에 저장
            self.saveToDiskCache(image: image, path: diskCachePath)
            
            completion(image)
        }
    }
    
    /**
     * 특정 비디오의 캐시된 썸네일 삭제
     * @param videoURL 비디오 파일 URL
     */
    func removeThumbnail(for videoURL: URL) {
        let cacheKey = cacheKey(for: videoURL)
        let diskCachePath = diskCachePath(for: videoURL)
        
        // 메모리 캐시에서 제거
        memoryCache.removeObject(forKey: cacheKey)
        
        // 디스크 캐시에서 제거
        try? fileManager.removeItem(at: diskCachePath)
    }
    
    /**
     * 모든 캐시 정리
     */
    func clearAllCache() {
        clearMemoryCache()
        clearDiskCache()
    }
    
    /**
     * 썸네일을 직접 캐시에 저장
     * @param image 저장할 썸네일 이미지
     * @param videoURL 비디오 파일 URL
     */
    func saveThumbnail(_ image: UIImage, for videoURL: URL) {
        let cacheKey = cacheKey(for: videoURL)
        let diskCachePath = diskCachePath(for: videoURL)
        
        // 메모리 캐시에 저장
        memoryCache.setObject(image, forKey: cacheKey)
        
        // 디스크 캐시에 저장
        saveToDiskCache(image: image, path: diskCachePath)
    }
    
    // MARK: - Private Methods
    
    /**
     * 비디오 URL로부터 캐시 키 생성
     * @param videoURL 비디오 파일 URL
     * @return 캐시 키 문자열
     */
    private func cacheKey(for videoURL: URL) -> NSString {
        return videoURL.lastPathComponent as NSString
    }
    
    /**
     * 비디오 URL로부터 디스크 캐시 경로 생성
     * @param videoURL 비디오 파일 URL
     * @return 디스크 캐시 파일 경로
     */
    private func diskCachePath(for videoURL: URL) -> URL {
        let fileName = videoURL.deletingPathExtension().lastPathComponent + ".jpg"
        return cacheDirectory.appendingPathComponent(fileName)
    }
    
    /**
     * AVAssetImageGenerator를 사용하여 썸네일 생성
     * @param videoURL 비디오 파일 URL
     * @param completion 생성 완료 시 호출되는 클로저
     */
    private func generateThumbnail(for videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        thumbnailQueue.async {
            let asset = AVAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            
            // 썸네일 생성 설정
            imageGenerator.appliesPreferredTrackTransform = true
            imageGenerator.maximumSize = CGSize(width: 120, height: 120)
            
            do {
                // 1초 지점에서 썸네일 생성
                let time = CMTime(seconds: 1.0, preferredTimescale: 600)
                let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
                let thumbnailImage = UIImage(cgImage: cgImage)
                
                DispatchQueue.main.async {
                    completion(thumbnailImage)
                }
                
            } catch {
                print("썸네일 생성 실패: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    /**
     * 이미지를 디스크 캐시에 저장
     * @param image 저장할 이미지
     * @param path 저장 경로
     */
    private func saveToDiskCache(image: UIImage, path: URL) {
        DispatchQueue.global(qos: .utility).async {
            guard let data = image.jpegData(compressionQuality: 0.8) else { return }
            
            try? data.write(to: path)
        }
    }
    
    /**
     * 메모리 캐시 정리
     */
    @objc private func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    /**
     * 디스크 캐시 정리
     */
    private func clearDiskCache() {
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Deinitializer
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
} 