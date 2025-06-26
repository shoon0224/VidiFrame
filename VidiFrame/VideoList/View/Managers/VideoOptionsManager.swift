//
//  VideoOptionsManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit

/**
 * 비디오 옵션 관리를 담당하는 클래스
 * 비디오 이름 변경, 썸네일 변경, 삭제 등의 기능을 관리
 */
class VideoOptionsManager {
    
    // MARK: - Properties
    
    /// 비디오 데이터를 제공하는 뷰모델
    weak var viewModel: VideoListViewModelProtocol?
    
    /// 옵션 화면을 표시할 뷰컨트롤러 (약한 참조)
    private weak var presentingViewController: UIViewController?
    
    /// 테이블뷰 업데이트를 위한 클로저
    var onTableViewUpdateRequired: (() -> Void)?
    
    /// 특정 행 업데이트를 위한 클로저
    var onRowUpdateRequired: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    /**
     * 초기화자
     * @param viewModel 비디오 데이터를 제공할 뷰모델
     * @param presentingViewController 옵션 화면을 표시할 뷰컨트롤러
     */
    init(viewModel: VideoListViewModelProtocol, presentingViewController: UIViewController) {
        self.viewModel = viewModel
        self.presentingViewController = presentingViewController
    }
    
    // MARK: - Public Methods
    
    /**
     * 비디오 옵션 액션 시트 표시
     * @param index 옵션을 표시할 비디오의 인덱스
     */
    func showVideoOptions(for index: Int) {
        guard let video = viewModel?.video(at: index),
              let presentingViewController = presentingViewController else { return }
        
        let actionSheet = UIAlertController(title: video.name, message: "원하는 작업을 선택하세요", preferredStyle: .actionSheet)
        
        // 비디오 이름 변경 액션
        actionSheet.addAction(UIAlertAction(title: "비디오 이름 변경", style: .default) { [weak self] _ in
            self?.showRenameDialog(for: index)
        })
        
        // 썸네일 변경 액션
        actionSheet.addAction(UIAlertAction(title: "썸네일 변경", style: .default) { [weak self] _ in
            self?.showThumbnailSelection(for: video)
        })
        
        // 비디오 삭제 액션
        actionSheet.addAction(UIAlertAction(title: "비디오 삭제", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: index)
        })
        
        // 취소 액션
        actionSheet.addAction(UIAlertAction(title: "취소", style: .cancel))
        
        // iPad에서 액션 시트가 제대로 표시되도록 popover 설정
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = presentingViewController.view
            popover.sourceRect = CGRect(x: presentingViewController.view.bounds.midX, y: presentingViewController.view.bounds.midY, width: 0, height: 0)
        }
        
        presentingViewController.present(actionSheet, animated: true)
    }
    
    /**
     * 비디오 삭제 확인 알림창 표시
     * @param index 삭제할 비디오의 인덱스
     */
    func showDeleteConfirmation(for index: Int) {
        guard let videoName = viewModel?.videoName(at: index),
              let presentingViewController = presentingViewController else { return }
        
        let alert = UIAlertController(
            title: "비디오 삭제",
            message: "'\(videoName)'을(를) 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.viewModel?.deleteVideo(at: index)
        })
        
        presentingViewController.present(alert, animated: true)
    }
    
    // MARK: - Private Methods
    
    /**
     * 비디오 이름 변경 다이얼로그 표시
     * @param index 이름을 변경할 비디오의 인덱스
     */
    private func showRenameDialog(for index: Int) {
        guard let video = viewModel?.video(at: index),
              let presentingViewController = presentingViewController else { return }
        
        let alert = UIAlertController(title: "비디오 이름 변경", message: "새로운 이름을 입력하세요", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.text = video.name
            textField.placeholder = "비디오 이름"
            textField.clearButtonMode = .whileEditing
        }
        
        // 확인 액션
        let confirmAction = UIAlertAction(title: "확인", style: .default) { [weak self] _ in
            guard let textField = alert.textFields?.first,
                  let newName = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !newName.isEmpty else {
                self?.showErrorAlert(message: "올바른 이름을 입력해주세요.")
                return
            }
            
            // 뷰모델에 이름 변경 요청
            self?.viewModel?.renameVideo(at: index, newName: newName)
            
            // 테이블뷰 해당 셀만 업데이트
            DispatchQueue.main.async {
                self?.onRowUpdateRequired?(index)
            }
        }
        
        // 취소 액션
        let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        alert.addAction(cancelAction)
        alert.addAction(confirmAction)
        
        presentingViewController.present(alert, animated: true) {
            // 텍스트 필드에 포커스를 주고 전체 텍스트 선택
            alert.textFields?.first?.selectAll(nil)
        }
    }
    
    /**
     * 썸네일 선택 화면 표시
     * @param video 썸네일을 변경할 비디오 모델
     */
    private func showThumbnailSelection(for video: VideoModel) {
        guard let presentingViewController = presentingViewController else { return }
        
        let thumbnailSelectionVC = ThumbnailSelectionViewController(videoURL: video.url) { [weak self] selectedImage in
            if selectedImage != nil {
                // 썸네일이 변경되었으므로 테이블뷰 리로드
                DispatchQueue.main.async {
                    self?.onTableViewUpdateRequired?()
                }
            }
        }
        
        presentingViewController.present(thumbnailSelectionVC, animated: true)
    }
    
    /**
     * 에러 알림 메시지 표시
     * @param message 표시할 에러 메시지
     */
    private func showErrorAlert(message: String) {
        guard let presentingViewController = presentingViewController else { return }
        
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        presentingViewController.present(alert, animated: true)
    }
} 