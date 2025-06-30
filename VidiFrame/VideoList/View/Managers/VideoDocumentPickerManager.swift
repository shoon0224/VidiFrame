//
//  VideoDocumentPickerManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

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
