//
//  VideoProgressManager.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/12/25.
//

import UIKit
import SnapKit

/**
 * 비디오 저장 진행률 UI를 관리하는 클래스
 * 프로그레스 바와 진행률 텍스트, 애니메이션 등을 담당
 */
class VideoProgressManager {
    
    // MARK: - UI Components
    
    /// 파일 저장 진행률을 표시하는 프로그레스 바
    private let progressView = UIProgressView(progressViewStyle: .default).then {
        $0.isHidden = true
        $0.progressTintColor = .label
        $0.trackTintColor = .systemGray4
        $0.layer.cornerRadius = 4.s
        $0.clipsToBounds = true
    }
    
    /// 파일 저장 진행률 텍스트 레이블 (몇 MB / 전체 MB, 퍼센트)
    private let progressLabel = UILabel().then {
        $0.isHidden = true
        $0.font = .systemFont(ofSize: 13, weight: .semibold)
        $0.textColor = .label
        $0.textAlignment = .center
        $0.numberOfLines = 1
    }
    
    /// 프로그레스 바와 레이블을 감싸는 Liquid Glass 컨테이너
    private let progressContainerView = LiquidGlassContainerView(
        cornerRadius: 20,
        style: .regular,
        presence: .prominent
    )
    
    /// 완료 메시지를 표시할 뷰컨트롤러 (약한 참조)
    private weak var presentingViewController: UIViewController?
    
    private let horizontalInset: CGFloat = 23
    
    // MARK: - Initialization
    
    /**
     * 초기화자
     * @param parentView 프로그레스 뷰를 추가할 부모 뷰
     * @param presentingViewController 완료 메시지를 표시할 뷰컨트롤러
     */
    init(parentView: UIView, presentingViewController: UIViewController) {
        self.presentingViewController = presentingViewController
        setupProgressViews(in: parentView)
    }
    
    // MARK: - Setup Methods
    
    /**
     * 프로그레스 관련 뷰들을 부모 뷰 중앙에 설정
     * @param parentView 부모 뷰
     */
    private func setupProgressViews(in parentView: UIView) {
        progressContainerView.isHidden = true
        
        parentView.addSubview(progressContainerView)
        progressContainerView.snp.makeConstraints {
            $0.center.equalTo(parentView.safeAreaLayoutGuide)
            $0.height.equalTo(72.s)
            // 가로 모드에서도 세로 모드와 비슷한 너비 유지 (짧은 변 기준)
            $0.width.lessThanOrEqualTo(parentView.snp.height).offset(-horizontalInset.s * 2)
            $0.width.equalTo(parentView.safeAreaLayoutGuide).offset(-horizontalInset.s * 2).priority(.high)
        }
        
        progressContainerView.contentView.addSubview(progressLabel)
        progressLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(14.s)
            $0.leading.trailing.equalToSuperview().inset(16.s)
        }
        
        progressContainerView.contentView.addSubview(progressView)
        progressView.snp.makeConstraints {
            $0.top.equalTo(progressLabel.snp.bottom).offset(12.s)
            $0.leading.trailing.equalToSuperview().inset(16.s)
            $0.height.equalTo(8.s)
        }
    }
    
    // MARK: - Public Methods
    
    /**
     * 파일 저장 진행률 업데이트
     * @param progress 저장 진행률 정보 (진행률, 복사된 바이트, 전체 바이트, 완료 여부)
     */
    func updateProgress(_ progress: VideoSaveProgress) {
        if progress.progress == 0.0 {
            // 저장 시작 시 진행률 뷰 표시
            showProgressView()
        }
        
        progressView.progress = Float(progress.progress)
        
        let progressPercentage = Int(progress.progress * 100)
        let totalMB = Double(progress.totalBytes) / (1024 * 1024)
        let copiedMB = Double(progress.copiedBytes) / (1024 * 1024)
        
        progressLabel.text = String(format: "저장 중 · %.1f/%.1f MB (%d%%)", copiedMB, totalMB, progressPercentage)
        
        if progress.isCompleted {
            // 저장 완료 시 0.5초 후 진행률 뷰 숨김
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.hideProgressView()
            }
        }
    }
    
    // MARK: - Private Methods
    
    /**
     * 파일 저장 진행률 뷰를 페이드인 애니메이션과 함께 표시
     */
    private func showProgressView() {
        progressContainerView.isHidden = false
        progressView.isHidden = false
        progressLabel.isHidden = false
        
        progressContainerView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.progressContainerView.alpha = 1.0
        }
    }
    
    /**
     * 파일 저장 진행률 뷰를 페이드아웃 애니메이션과 함께 숨기고 완료 메시지 표시
     */
    private func hideProgressView() {
        UIView.animate(withDuration: 0.3) {
            self.progressContainerView.alpha = 0
        } completion: { _ in
            self.progressContainerView.isHidden = true
            self.progressView.isHidden = true
            self.progressLabel.isHidden = true
            self.progressView.progress = 0
            
            // 저장 완료 메시지 표시
            self.showSuccessMessage()
        }
    }
    
    /**
     * 저장 완료 알림 메시지 표시
     */
    private func showSuccessMessage() {
        guard let presentingViewController = presentingViewController else { return }
        
        let alert = UIAlertController(title: "저장 완료", message: "비디오가 성공적으로 저장되었습니다.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        presentingViewController.present(alert, animated: true)
    }
} 