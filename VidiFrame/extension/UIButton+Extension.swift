//
//  UIButton+Extension.swift
//  VidiFrame
//
//  Created by 이상훈 on 4/12/25.
//

import UIKit

extension UIButton {
    
    //터치 애니메이션
    func pressAnimation(scale: CGFloat = 0.95, duration: TimeInterval = 0.1) {
        self.addTarget(self, action: #selector(animateDown), for: [.touchDown])
        self.addTarget(self, action: #selector(animateUp), for: [.touchUpInside, .touchUpOutside, .touchCancel])
    }
    
    @objc private func animateDown() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        })
    }
    
    @objc private func animateUp() {
        UIView.animate(withDuration: 0.1, animations: {
            self.transform = .identity
        })
    }
}
