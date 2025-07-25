//
//  DeviceScale.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/13/25.
//

import UIKit

/**
 * 디바이스별 스케일 팩터 정의
 * iPhone 14 Pro (393x852)를 기준(1.0)으로 각 디바이스별 비율 계산
 */
struct DeviceScale {
    
    // MARK: - 기준 디바이스 스펙
    static let baseWidth: CGFloat = 393.0  // iPhone 14 Pro 기준
    static let baseHeight: CGFloat = 852.0 // iPhone 14 Pro 기준
    
    // MARK: - 디바이스 식별
    enum DeviceType {
        case iPhoneSE3rd           // 375 x 667
        case iPhone12Mini          // 375 x 812
        case iPhone12              // 390 x 844
        case iPhone12Pro           // 390 x 844
        case iPhone12ProMax        // 428 x 926
        case iPhone13Mini          // 375 x 812
        case iPhone13              // 390 x 844
        case iPhone13Pro           // 393 x 852
        case iPhone13ProMax        // 428 x 926
        case iPhone14              // 390 x 844
        case iPhone14Plus          // 428 x 926
        case iPhone14Pro           // 393 x 852 (기준)
        case iPhone14ProMax        // 430 x 932
        case iPhone15              // 393 x 852
        case iPhone15Plus          // 430 x 932
        case iPhone15Pro           // 393 x 852
        case iPhone15ProMax        // 430 x 932
        case iPadMini              // 768 x 1024
        case iPadAir               // 820 x 1180
        case iPadPro11             // 834 x 1194
        case iPadPro12_9           // 1024 x 1366
        case unknown
    }
    
    // MARK: - 디바이스별 스케일 팩터
    static let deviceScales: [DeviceType: (horizontal: CGFloat, vertical: CGFloat)] = [
        // iPhone SE 시리즈 - 작은 화면
        .iPhoneSE3rd: (horizontal: 0.85, vertical: 0.90),
        
        // iPhone 12 시리즈
        .iPhone12Mini: (horizontal: 0.88, vertical: 0.95),
        .iPhone12: (horizontal: 0.96, vertical: 0.98),
        .iPhone12Pro: (horizontal: 0.96, vertical: 0.98),
        .iPhone12ProMax: (horizontal: 1.08, vertical: 1.06),
        
        // iPhone 13 시리즈
        .iPhone13Mini: (horizontal: 0.88, vertical: 0.95),
        .iPhone13: (horizontal: 0.96, vertical: 0.98),
        .iPhone13Pro: (horizontal: 1.0, vertical: 1.0),   // 기준과 동일
        .iPhone13ProMax: (horizontal: 1.08, vertical: 1.06),
        
        // iPhone 14 시리즈
        .iPhone14: (horizontal: 0.96, vertical: 0.98),
        .iPhone14Plus: (horizontal: 1.08, vertical: 1.06),
        .iPhone14Pro: (horizontal: 1.0, vertical: 1.0),   // 기준 디바이스
        .iPhone14ProMax: (horizontal: 1.09, vertical: 1.08),
        
        // iPhone 15 시리즈
        .iPhone15: (horizontal: 1.0, vertical: 1.0),
        .iPhone15Plus: (horizontal: 1.09, vertical: 1.08),
        .iPhone15Pro: (horizontal: 1.0, vertical: 1.0),
        .iPhone15ProMax: (horizontal: 1.09, vertical: 1.08),
        
        // iPad 시리즈 - 태블릿은 별도 스케일링 필요
        .iPadMini: (horizontal: 1.8, vertical: 1.4),
        .iPadAir: (horizontal: 2.0, vertical: 1.6),
        .iPadPro11: (horizontal: 2.1, vertical: 1.7),
        .iPadPro12_9: (horizontal: 2.5, vertical: 2.0),
        
        // 알 수 없는 디바이스
        .unknown: (horizontal: 1.0, vertical: 1.0)
    ]
    
    // MARK: - 컴포넌트별 가중치
    static let componentWeights: [ComponentType: CGFloat] = [
        .text: 0.9,           // 텍스트는 상대적으로 작게
        .button: 1.0,         // 버튼은 기본 비율
        .image: 1.1,          // 이미지는 약간 크게
        .spacing: 0.8,        // 여백은 작게
        .cornerRadius: 1.0,   // 둥근 모서리는 기본
        .borderWidth: 0.7     // 테두리는 작게
    ]
    
    enum ComponentType {
        case text
        case button
        case image
        case spacing
        case cornerRadius
        case borderWidth
    }
    
    // MARK: - 현재 디바이스 타입 감지
    static var currentDeviceType: DeviceType {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let screenSize = max(screenWidth, screenHeight) // 세로 기준
        
        switch screenSize {
        case 667:
            return .iPhoneSE3rd
        case 812:
            return screenWidth <= 375 ? .iPhone12Mini : .iPhone13Mini
        case 844:
            return .iPhone12
        case 852:
            return .iPhone14Pro
        case 926:
            return .iPhone12ProMax
        case 932:
            return .iPhone14ProMax
        case 1024:
            return .iPadMini
        case 1180:
            return .iPadAir
        case 1194:
            return .iPadPro11
        case 1366:
            return .iPadPro12_9
        default:
            return .unknown
        }
    }
    
    // MARK: - 현재 디바이스의 스케일 팩터 가져오기
    static var currentHorizontalScale: CGFloat {
        return deviceScales[currentDeviceType]?.horizontal ?? 1.0
    }
    
    static var currentVerticalScale: CGFloat {
        return deviceScales[currentDeviceType]?.vertical ?? 1.0
    }
    
    // MARK: - Safe Area 고려한 스케일 팩터
    static var safeAreaAdjustedHorizontalScale: CGFloat {
        let safeArea = getCurrentSafeAreaInsets()
        let availableWidth = UIScreen.main.bounds.width - safeArea.left - safeArea.right
        let baseAvailableWidth = baseWidth - 40 // 기준 디바이스의 예상 Safe Area
        
        return (availableWidth / baseAvailableWidth) * currentHorizontalScale
    }
    
    static var safeAreaAdjustedVerticalScale: CGFloat {
        let safeArea = getCurrentSafeAreaInsets()
        let availableHeight = UIScreen.main.bounds.height - safeArea.top - safeArea.bottom
        let baseAvailableHeight = baseHeight - 100 // 기준 디바이스의 예상 Safe Area
        
        return (availableHeight / baseAvailableHeight) * currentVerticalScale
    }
    
    // MARK: - Safe Area Insets 가져오기 (iOS 15+ 대응)
    private static func getCurrentSafeAreaInsets() -> UIEdgeInsets {
        // iOS 15+ 방식
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets
        }
        
        // 백업 방식 (iOS 15 미만 또는 window를 찾을 수 없는 경우)
        if #available(iOS 15.0, *) {
            // iOS 15+에서도 연결된 씬이 없는 경우의 백업
            return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0) // 일반적인 Safe Area 기본값
        } else {
            // iOS 15 미만
            return UIApplication.shared.windows.first?.safeAreaInsets ?? UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
        }
    }
    
    // MARK: - 디바이스 정보 출력 (디버깅용)
    static func printDeviceInfo() {
        let device = currentDeviceType
        let scale = deviceScales[device] ?? (1.0, 1.0)
        
        print("=== 디바이스 스케일 정보 ===")
        print("현재 디바이스: \(device)")
        print("화면 크기: \(UIScreen.main.bounds.size)")
        print("가로 스케일: \(scale.horizontal)")
        print("세로 스케일: \(scale.vertical)")
        print("Safe Area 조정 가로: \(safeAreaAdjustedHorizontalScale)")
        print("Safe Area 조정 세로: \(safeAreaAdjustedVerticalScale)")
        print("========================")
    }
} 