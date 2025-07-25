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
    /// DeviceScale을 적용한 기본 스케일링 (가로 기준)
    var s: CGFloat {
        return self * DeviceScale.safeAreaAdjustedHorizontalScale
    }
    
    /// DeviceScale을 적용한 세로 스케일링
    var sV: CGFloat {
        return self * DeviceScale.safeAreaAdjustedVerticalScale
    }
    
    /// 버튼용 스케일링 (가중치 적용)
    var sButton: CGFloat {
        let buttonWeight = DeviceScale.componentWeights[.button] ?? 1.0
        return self * DeviceScale.safeAreaAdjustedHorizontalScale * buttonWeight
    }
    
    /// 여백용 스케일링 (가중치 적용)
    var sSpacing: CGFloat {
        let spacingWeight = DeviceScale.componentWeights[.spacing] ?? 1.0
        return self * DeviceScale.safeAreaAdjustedHorizontalScale * spacingWeight
    }
    
    /// 텍스트용 스케일링 (가중치 적용)
    var sText: CGFloat {
        let textWeight = DeviceScale.componentWeights[.text] ?? 1.0
        return self * DeviceScale.safeAreaAdjustedHorizontalScale * textWeight
    }
    
    /// 이미지용 스케일링 (가중치 적용)
    var sImage: CGFloat {
        let imageWeight = DeviceScale.componentWeights[.image] ?? 1.0
        return self * DeviceScale.safeAreaAdjustedHorizontalScale * imageWeight
    }
}

extension Float {
    /// DeviceScale을 적용한 기본 스케일링
    var s: CGFloat {
        return CGFloat(self).s
    }
    
    /// DeviceScale을 적용한 세로 스케일링
    var sV: CGFloat {
        return CGFloat(self).sV
    }
    
    /// 버튼용 스케일링
    var sButton: CGFloat {
        return CGFloat(self).sButton
    }
    
    /// 여백용 스케일링
    var sSpacing: CGFloat {
        return CGFloat(self).sSpacing
    }
    
    /// 텍스트용 스케일링
    var sText: CGFloat {
        return CGFloat(self).sText
    }
    
    /// 이미지용 스케일링
    var sImage: CGFloat {
        return CGFloat(self).sImage
    }
}

extension Double {
    /// DeviceScale을 적용한 기본 스케일링
    var s: CGFloat {
        return CGFloat(self).s
    }
    
    /// DeviceScale을 적용한 세로 스케일링
    var sV: CGFloat {
        return CGFloat(self).sV
    }
    
    /// 버튼용 스케일링
    var sButton: CGFloat {
        return CGFloat(self).sButton
    }
    
    /// 여백용 스케일링
    var sSpacing: CGFloat {
        return CGFloat(self).sSpacing
    }
    
    /// 텍스트용 스케일링
    var sText: CGFloat {
        return CGFloat(self).sText
    }
    
    /// 이미지용 스케일링
    var sImage: CGFloat {
        return CGFloat(self).sImage
    }
}

extension Int {
    /// DeviceScale을 적용한 기본 스케일링
    var s: CGFloat {
        return CGFloat(self).s
    }
    
    /// DeviceScale을 적용한 세로 스케일링
    var sV: CGFloat {
        return CGFloat(self).sV
    }
    
    /// 버튼용 스케일링
    var sButton: CGFloat {
        return CGFloat(self).sButton
    }
    
    /// 여백용 스케일링
    var sSpacing: CGFloat {
        return CGFloat(self).sSpacing
    }
    
    /// 텍스트용 스케일링
    var sText: CGFloat {
        return CGFloat(self).sText
    }
    
    /// 이미지용 스케일링
    var sImage: CGFloat {
        return CGFloat(self).sImage
    }
}
