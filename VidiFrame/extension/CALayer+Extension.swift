//
//  CALayer+Extension.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/12/25.
//

import UIKit

extension CALayer {
    /// - Parameters:
    ///   - color: 그림자 색. 기본 값 검정색
    ///   - alpha: 알파 값. 기본 값 0.5
    ///   - x: x 좌표 포인트. 기본 값 0
    ///   - y: y 좌표 포인트. 기본 값 2
    ///   - blur: 블러. 기본 값 4
    ///   - spread: 그림자 퍼지는 정도, zeplin spread 값. 기본 값 0
    func applyShadow(color: UIColor = .black, alpha: Float = 0.5, x: CGFloat = 0, y: CGFloat = 2, blur: CGFloat = 4, spread: CGFloat = 0) {
        masksToBounds = false
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
        if spread == 0 {
            shadowPath = nil
        } else {
            let dx = -spread
            let rect = bounds.insetBy(dx: dx, dy: dx)
            shadowPath = UIBezierPath(rect: rect).cgPath
        }
    }
}
