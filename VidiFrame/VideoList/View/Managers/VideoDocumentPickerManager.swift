//
//  VideoDocumentPickerManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
import PhotosUI

/**
 * 비디오 파일 선택을 위한 문서 피커 관리 클래스
 * UIDocumentPickerViewController를 관리하고 선택된 파일을 처리
 */
class VideoDocumentPickerManager: NSObject {
    
    // MARK: - Properties
    
    /// 비디오 파일을 추가할 뷰모델
    weak var viewModel: VideoListViewModelProtocol?
    
    /// 문서 피커를 표시할 뷰컨트롤러 (약한 참조)
    private weak var presentingViewController: UIViewController?
    
    // MARK: - Initialization
    
    /**
     * @param viewModel 비디오 파일을 추가할 뷰모델
     * @param presentingViewController 문서 피커를 표시할 뷰컨트롤러
     */
    init(viewModel: VideoListViewModelProtocol, presentingViewController: UIViewController) {
        self.viewModel = viewModel
        self.presentingViewController = presentingViewController
        super.init()
    }
    
    // MARK: - Public Methods
    
    /**
     * 비디오 파일 선택을 위한 문서 피커 표시
     * 지원되는 비디오 형식의 파일을 선택할 수 있는 문서 선택기 표시
     */
    func presentDocumentPicker() {
        guard let presentingViewController = presentingViewController else { return }
        
        let supportedTypes: [UTType] = [.movie, .mpeg4Movie, .video]
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes, asCopy: true)
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        presentingViewController.present(documentPicker, animated: true)
    }
    
    /**
     * 사진첩에서 비디오 선택을 위한 PHPickerViewController 표시
     * 사진첩에서 비디오만 선택할 수 있도록 구성
     */
    func presentPhotoLibraryVideoPicker() {
        guard let presentingViewController = presentingViewController else { return }
        
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos // 비디오만 선택 가능
        configuration.selectionLimit = 1 // 한 번에 하나의 비디오만 선택
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        presentingViewController.present(picker, animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension VideoDocumentPickerManager: UIDocumentPickerDelegate {
    
    /**
     * 문서 선택기에서 파일 선택 완료 시 호출
     * 선택된 비디오 파일을 뷰모델에 추가 요청
     * @param controller 문서 선택기 인스턴스
     * @param urls 선택된 파일들의 URL 배열
     */
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let sourceURL = urls.first else { return }
        viewModel?.addVideo(sourceURL)
    }
    
    /**
     * 문서 선택기가 취소되었을 때 호출 (선택사항)
     * @param controller 문서 선택기 인스턴스
     */
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        // 필요시 취소 처리 로직 구현
        print("문서 선택이 취소되었습니다.")
    }
}

// MARK: - PHPickerViewControllerDelegate
extension VideoDocumentPickerManager: PHPickerViewControllerDelegate {
    
    /**
     * 사진첩에서 비디오 선택 완료 시 호출
     * 선택된 비디오 파일을 앱 내부 저장소에 복사한 후 뷰모델에 추가 요청
     * @param picker 사진 선택기 인스턴스
     * @param results 선택된 항목들의 결과 배열
     */
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let result = results.first else { return }
        
        // 비디오 파일 처리
        if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                if let error = error {
                    print("비디오 로드 오류: \(error)")
                    return
                }
                
                guard let sourceURL = url else { return }
                
                // 파일을 앱 내부 Documents 디렉토리에 복사
                self?.copyVideoToDocuments(from: sourceURL)
            }
        }
    }
    
    /**
     * 사진첩에서 선택한 비디오 파일을 앱 내부 Documents 디렉토리에 복사
     * @param sourceURL 사진첩에서 선택한 비디오 파일의 임시 URL
     */
    private func copyVideoToDocuments(from sourceURL: URL) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let fileName = "video_\(Date().timeIntervalSince1970).\(sourceURL.pathExtension)"
        let destinationURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            // 파일 복사
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
            
            // 메인 스레드에서 뷰모델에 추가
            DispatchQueue.main.async { [weak self] in
                self?.viewModel?.addVideo(destinationURL)
            }
        } catch {
            print("비디오 복사 오류: \(error)")
        }
    }
} 
