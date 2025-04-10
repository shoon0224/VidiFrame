//
//  extension.swift
//  VidiFrame
//
//  Created by 이상훈 on 2/13/25.
//

import UIKit

extension UIScreen {
    /// 디바이스 화면 넓이
    static var width: CGFloat { //main.bounds 빼서 줄이기
        return UIScreen.main.bounds.width
    }
    
    /// 디바이스 화면 높이
    static var height: CGFloat { //main.bounds 빼서 줄이기
        return UIScreen.main.bounds.height
    }
}

extension CGFloat {
    /// 디바이스 화면 비율에 맞춘 값을 반환
    var s: CGFloat {
        let baseWidth: CGFloat = 376 //가로 길이가 376인 아이폰을 기준으로 앱을 비율 디자인 한다.
        return (self / baseWidth) * UIScreen.main.bounds.width
    }
}

extension Float {
    /// 디바이스 화면 비율에 맞춘 값을 반환
    var s: CGFloat {
        return CGFloat(self).s
    }
}

extension Double {
    /// 디바이스 화면 비율에 맞춘 값을 반환
    var s: CGFloat {
        return CGFloat(self).s
    }
}
