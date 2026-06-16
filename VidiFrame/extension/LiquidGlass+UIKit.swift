//
//  LiquidGlass+UIKit.swift
//  VidiFrame
//

import UIKit

enum LiquidGlassStyle {
    case regular
    case clear
}

enum GlassPresence {
    case subtle
    case standard
    case elevated
    case prominent
}

enum LiquidGlass {
    
    static func makeEffect(
        style: LiquidGlassStyle = .regular,
        tintColor: UIColor? = nil,
        isInteractive: Bool = false
    ) -> UIVisualEffect {
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect(style: style == .clear ? .clear : .regular)
            glassEffect.tintColor = tintColor
            glassEffect.isInteractive = isInteractive
            return glassEffect
        }
        
        let blurStyle: UIBlurEffect.Style
        switch style {
        case .clear:
            blurStyle = .systemThinMaterial
        case .regular:
            blurStyle = .systemMaterial
        }
        return UIBlurEffect(style: blurStyle)
    }
    
    static func fillColor(for presence: GlassPresence, style: LiquidGlassStyle, traitCollection: UITraitCollection) -> UIColor {
        let isDark = traitCollection.userInterfaceStyle == .dark
        switch (presence, style, isDark) {
        case (.subtle, _, true):
            return UIColor.white.withAlphaComponent(0.05)
        case (.subtle, _, false):
            return UIColor.white.withAlphaComponent(0.38)
        case (.standard, .clear, true):
            return UIColor.white.withAlphaComponent(0.08)
        case (.standard, .clear, false):
            return UIColor.white.withAlphaComponent(0.52)
        case (.standard, .regular, true):
            return UIColor.white.withAlphaComponent(0.1)
        case (.standard, .regular, false):
            return UIColor.white.withAlphaComponent(0.58)
        case (.elevated, .clear, true):
            return UIColor.white.withAlphaComponent(0.11)
        case (.elevated, .clear, false):
            return UIColor.white.withAlphaComponent(0.62)
        case (.elevated, .regular, true):
            return UIColor.white.withAlphaComponent(0.13)
        case (.elevated, .regular, false):
            return UIColor.white.withAlphaComponent(0.68)
        case (.prominent, _, true):
            return UIColor.black.withAlphaComponent(0.36)
        case (.prominent, _, false):
            return UIColor.label.withAlphaComponent(0.14)
        }
    }
    
    static func resolvedTintColor(
        _ tintColor: UIColor?,
        presence: GlassPresence,
        style: LiquidGlassStyle,
        traitCollection: UITraitCollection
    ) -> UIColor? {
        if let tintColor {
            return tintColor
        }
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let baseAlpha: CGFloat
        switch presence {
        case .subtle: baseAlpha = isDark ? 0.06 : 0.04
        case .standard: baseAlpha = isDark ? 0.1 : 0.07
        case .elevated: baseAlpha = isDark ? 0.14 : 0.1
        case .prominent: baseAlpha = isDark ? 0.16 : 0.22
        }
        
        let styleBoost: CGFloat = style == .clear ? 0.85 : 1.0
        return UIColor.label.withAlphaComponent(baseAlpha * styleBoost)
    }
    
    static func makeContainerEffect(spacing: CGFloat = 40) -> UIVisualEffect? {
        if #available(iOS 26.0, *) {
            let containerEffect = UIGlassContainerEffect()
            containerEffect.spacing = spacing
            return containerEffect
        }
        return nil
    }
    
    static func configureScrollEdges(for scrollView: UIScrollView) {
        if #available(iOS 26.0, *) {
            scrollView.topEdgeEffect.style = .automatic
            scrollView.bottomEdgeEffect.style = .automatic
        }
    }
    
    static func addBottomScrollEdgeInteraction(to overlayView: UIView, scrollView: UIScrollView) {
        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = scrollView
            interaction.edge = .bottom
            overlayView.addInteraction(interaction)
        }
    }
}

/// iOS 26 Liquid Glass 스타일의 그라데이션 배경
final class LiquidGlassBackgroundView: UIView {
    
    private let baseGradientLayer = CAGradientLayer()
    private let orbLayers: [CAGradientLayer] = (0..<3).map { _ in CAGradientLayer() }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    private func setupLayers() {
        baseGradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor,
            UIColor.tertiarySystemBackground.cgColor
        ]
        baseGradientLayer.locations = [0, 0.55, 1]
        baseGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        baseGradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(baseGradientLayer)
        
        let orbColors: [[UIColor]] = [
            [UIColor.label.withAlphaComponent(0.12), UIColor.clear],
            [UIColor.secondaryLabel.withAlphaComponent(0.1), UIColor.clear],
            [UIColor.tertiaryLabel.withAlphaComponent(0.08), UIColor.clear]
        ]
        
        orbLayers.enumerated().forEach { index, orbLayer in
            orbLayer.type = .radial
            orbLayer.colors = orbColors[index].map(\.cgColor)
            orbLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
            orbLayer.endPoint = CGPoint(x: 1, y: 1)
            orbLayer.opacity = 1
            layer.addSublayer(orbLayer)
        }
        
        startAmbientAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        baseGradientLayer.frame = bounds
        
        let width = bounds.width
        let height = bounds.height
        orbLayers[0].frame = CGRect(x: -width * 0.25, y: -height * 0.15, width: width * 1.1, height: width * 1.1)
        orbLayers[1].frame = CGRect(x: width * 0.35, y: height * 0.15, width: width, height: width)
        orbLayers[2].frame = CGRect(x: -width * 0.1, y: height * 0.45, width: width * 0.95, height: width * 0.95)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        
        baseGradientLayer.colors = [
            UIColor.systemBackground.cgColor,
            UIColor.secondarySystemBackground.cgColor,
            UIColor.tertiarySystemBackground.cgColor
        ]
    }
    
    private func startAmbientAnimation() {
        orbLayers.enumerated().forEach { index, orbLayer in
            let animation = CABasicAnimation(keyPath: "transform.translation")
            animation.fromValue = NSValue(cgPoint: .zero)
            animation.toValue = NSValue(cgPoint: CGPoint(x: index.isMultiple(of: 2) ? 18 : -14, y: index == 1 ? -20 : 16))
            animation.duration = 8 + Double(index) * 1.5
            animation.autoreverses = true
            animation.repeatCount = .infinity
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            orbLayer.add(animation, forKey: "liquidGlassDrift")
        }
    }
}

/// Liquid Glass 재질을 적용하는 컨테이너 뷰
final class LiquidGlassContainerView: UIView {
    
    private let clipContainerView = UIView()
    private let fillView = UIView()
    private let effectView: UIVisualEffectView
    private let highlightView = UIView()
    let contentView = UIView()
    
    private var cornerRadius: CGFloat
    private var glassStyle: LiquidGlassStyle
    private var glassPresence: GlassPresence
    private var customTintColor: UIColor?
    private var isInteractiveGlass: Bool
    
    init(
        cornerRadius: CGFloat = 20,
        style: LiquidGlassStyle = .regular,
        tintColor: UIColor? = nil,
        isInteractive: Bool = false,
        presence: GlassPresence = .standard,
        containerSpacing: CGFloat? = nil
    ) {
        self.cornerRadius = cornerRadius
        self.glassStyle = style
        self.glassPresence = presence
        self.customTintColor = tintColor
        self.isInteractiveGlass = isInteractive
        
        if let containerSpacing,
           let containerEffect = LiquidGlass.makeContainerEffect(spacing: containerSpacing) {
            effectView = UIVisualEffectView(effect: containerEffect)
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        }
        
        super.init(frame: .zero)
        
        backgroundColor = .clear
        setupHierarchy()
        applyAppearance()
    }
    
    required init?(coder: NSCoder) {
        cornerRadius = 20
        glassStyle = .regular
        glassPresence = .standard
        customTintColor = nil
        isInteractiveGlass = false
        effectView = UIVisualEffectView(effect: LiquidGlass.makeEffect())
        super.init(coder: coder)
        setupHierarchy()
        applyAppearance()
    }
    
    private func setupHierarchy() {
        addSubview(clipContainerView)
        clipContainerView.addSubview(fillView)
        clipContainerView.addSubview(effectView)
        clipContainerView.addSubview(highlightView)
        clipContainerView.addSubview(contentView)
        
        clipContainerView.translatesAutoresizingMaskIntoConstraints = false
        fillView.translatesAutoresizingMaskIntoConstraints = false
        effectView.translatesAutoresizingMaskIntoConstraints = false
        highlightView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            clipContainerView.topAnchor.constraint(equalTo: topAnchor),
            clipContainerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            clipContainerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            clipContainerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            fillView.topAnchor.constraint(equalTo: clipContainerView.topAnchor),
            fillView.leadingAnchor.constraint(equalTo: clipContainerView.leadingAnchor),
            fillView.trailingAnchor.constraint(equalTo: clipContainerView.trailingAnchor),
            fillView.bottomAnchor.constraint(equalTo: clipContainerView.bottomAnchor),
            
            effectView.topAnchor.constraint(equalTo: clipContainerView.topAnchor),
            effectView.leadingAnchor.constraint(equalTo: clipContainerView.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: clipContainerView.trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: clipContainerView.bottomAnchor),
            
            highlightView.topAnchor.constraint(equalTo: clipContainerView.topAnchor),
            highlightView.leadingAnchor.constraint(equalTo: clipContainerView.leadingAnchor),
            highlightView.trailingAnchor.constraint(equalTo: clipContainerView.trailingAnchor),
            highlightView.heightAnchor.constraint(equalToConstant: 1),
            
            contentView.topAnchor.constraint(equalTo: clipContainerView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: clipContainerView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: clipContainerView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: clipContainerView.bottomAnchor)
        ])
        
        clipContainerView.clipsToBounds = true
        effectView.clipsToBounds = true
        contentView.backgroundColor = .clear
        highlightView.isUserInteractionEnabled = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipContainerView.layer.cornerRadius = cornerRadius
        clipContainerView.layer.cornerCurve = .continuous
        fillView.layer.cornerRadius = cornerRadius
        fillView.layer.cornerCurve = .continuous
        effectView.layer.cornerRadius = cornerRadius
        effectView.layer.cornerCurve = .continuous
        
        layer.shadowPath = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: cornerRadius
        ).cgPath
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        applyAppearance()
    }
    
    private func applyAppearance() {
        fillView.backgroundColor = LiquidGlass.fillColor(
            for: glassPresence,
            style: glassStyle,
            traitCollection: traitCollection
        )
        
        let resolvedTint = LiquidGlass.resolvedTintColor(
            customTintColor,
            presence: glassPresence,
            style: glassStyle,
            traitCollection: traitCollection
        )
        effectView.effect = LiquidGlass.makeEffect(
            style: glassStyle,
            tintColor: resolvedTint,
            isInteractive: isInteractiveGlass
        )
        
        let isDark = traitCollection.userInterfaceStyle == .dark
        let highlightAlpha: CGFloat
        switch glassPresence {
        case .subtle:
            highlightAlpha = isDark ? 0.1 : 0.55
        case .standard:
            highlightAlpha = isDark ? 0.12 : 0.6
        case .elevated:
            highlightAlpha = isDark ? 0.16 : 0.72
        case .prominent:
            highlightAlpha = isDark ? 0.14 : 0.45
        }
        highlightView.backgroundColor = UIColor.white.withAlphaComponent(highlightAlpha)
        
        let shadowOpacity: Float
        let shadowRadius: CGFloat
        let shadowY: CGFloat
        switch glassPresence {
        case .subtle:
            shadowOpacity = isDark ? 0.22 : 0.06
            shadowRadius = 10
            shadowY = 4
        case .standard:
            shadowOpacity = isDark ? 0.28 : 0.08
            shadowRadius = 14
            shadowY = 6
        case .elevated:
            shadowOpacity = isDark ? 0.34 : 0.1
            shadowRadius = 18
            shadowY = 8
        case .prominent:
            shadowOpacity = isDark ? 0.42 : 0.14
            shadowRadius = 22
            shadowY = 10
        }
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = CGSize(width: 0, height: shadowY)
    }
    
    func updateGlassEffect(
        style: LiquidGlassStyle = .regular,
        tintColor: UIColor? = nil,
        isInteractive: Bool = false,
        presence: GlassPresence? = nil,
        animated: Bool = true
    ) {
        glassStyle = style
        customTintColor = tintColor
        isInteractiveGlass = isInteractive
        if let presence {
            glassPresence = presence
        }
        
        let apply = { self.applyAppearance() }
        guard animated else {
            apply()
            return
        }
        
        UIView.animate(withDuration: 0.25, animations: apply)
    }
}
