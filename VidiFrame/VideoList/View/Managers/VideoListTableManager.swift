//
//  VideoListTableManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit

/**
 * 비디오 목록 테이블뷰의 DataSource와 Delegate를 관리하는 클래스
 * VideoListViewController의 테이블뷰 관련 로직을 분리하여 관리
 */
class VideoListTableManager: NSObject {
    
    // MARK: - Properties
    
    /// 비디오 데이터를 제공하는 뷰모델
    weak var viewModel: VideoListViewModelProtocol?
    
    /// 비디오 옵션 선택 시 호출되는 클로저
    var onVideoOptionsSelected: ((Int) -> Void)?
    
    /// 비디오 삭제 확인 요청 시 호출되는 클로저
    var onDeleteConfirmationRequested: ((Int) -> Void)?
    
    /// 비디오 선택 시 호출되는 클로저 (재생 등)
    var onVideoSelected: ((Int) -> Void)?
    
    // MARK: - Initialization
    
    /**
     * 초기화자
     * @param viewModel 비디오 데이터를 제공할 뷰모델
     */
    init(viewModel: VideoListViewModelProtocol) {
        self.viewModel = viewModel
        super.init()
    }
}

// MARK: - UITableViewDataSource
extension VideoListTableManager: UITableViewDataSource {
    
    /**
     * 테이블뷰 섹션 내 행의 개수 반환
     * @param tableView 테이블뷰 인스턴스
     * @param section 섹션 번호
     * @return 비디오 개수
     */
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfVideos() ?? 0
    }
    
    /**
     * 테이블뷰 셀 구성
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 셀의 인덱스 경로
     * @return 구성된 비디오 셀
     */
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: VideoCell.identifier, for: indexPath) as? VideoCell else {
            return UITableViewCell()
        }
        
        if let video = viewModel?.video(at: indexPath.row) {
            cell.configure(with: video)
            
            // 옵션 버튼 콜백 설정
            cell.onOptionsButtonTapped = { [weak self] in
                self?.onVideoOptionsSelected?(indexPath.row)
            }
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension VideoListTableManager: UITableViewDelegate {
    
    /**
     * 테이블뷰 셀의 높이 지정
     * 가로/세로 모드에 따라 적절한 높이 반환
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 셀의 인덱스 경로
     * @return 셀 높이 (가로 모드: 74, 세로 모드: 84)
     */
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // 가로 모드에서는 높이를 줄여서 더 많은 셀이 보이도록 함
        let isLandscape = tableView.frame.width > tableView.frame.height
        return isLandscape ? 74 : 84
    }
    
    /**
     * 테이블뷰 셀 편집 스타일 처리 (스와이프 삭제)
     * @param tableView 테이블뷰 인스턴스
     * @param editingStyle 편집 스타일 (.delete)
     * @param indexPath 편집할 셀의 인덱스 경로
     */
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            onDeleteConfirmationRequested?(indexPath.row)
        }
    }
    
    /**
     * 테이블뷰 셀 선택 시 호출
     * @param tableView 테이블뷰 인스턴스
     * @param indexPath 선택된 셀의 인덱스 경로
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // 터치 피드백 (중간 강도 햅틱)
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        onVideoSelected?(indexPath.row)
    }
} 
