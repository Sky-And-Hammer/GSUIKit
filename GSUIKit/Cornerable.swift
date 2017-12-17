//
//  Cornerable.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSFoundation
import GSStability

/// inner protocol 圆角
protocol Cornerable: class {
    
    var radius: CGFloat { get set }
    var radiusLayer: CAShapeLayer? { get }
    var isCircle: Bool { get set }
}

private var kGSRadius = "\(#file)+\(#line)"
private var kGSRadiusLayer = "\(#file)+\(#line)"
private var kGSIsCircle = "\(#file)+\(#line)"

extension UIView: Cornerable {
    
    /// 倒角 值
    public var radius: CGFloat {
        get { return objc_getAssociatedObject(self, &kGSRadius) as? CGFloat ?? 0.0 }
        set {
            objc_setAssociatedObject(self, &kGSRadius, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue > 0.0 { innerLoad() }
        }
    }
    
    /// 实现倒角的 layer
    public var radiusLayer: CAShapeLayer? { return _radisuLayer }
    
    private var _radisuLayer: CAShapeLayer? {
        get { return objc_getAssociatedObject(self, &kGSRadiusLayer) as? CAShapeLayer }
        set {
            objc_setAssociatedObject(self, &kGSRadiusLayer, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    /// 是否 圆角
    var isCircle: Bool {
        get { return objc_getAssociatedObject(self, &kGSIsCircle) as? Bool ?? false }
        set {
            objc_setAssociatedObject(self, &kGSIsCircle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue { innerLoad() }
        }
    }
    
    private func innerLoad() {
        DispatchQueue.once(token: "GSRadiusable", block: {
            UIView.swizzleInstanceMethod(origSelector: #selector(layoutSubviews), toAlterSelector: #selector(_radiusLayoutSubviews))
        })
        
        _radisuLayer = CAShapeLayer().then { layer.mask = $0 }
        setNeedsLayout()
    }
}

// MARK: - Swizzle Methods

extension UIView {
    @objc func _radiusLayoutSubviews() {
        self._radiusLayoutSubviews()
        
        guard let layer = radiusLayer, (radius > 0.0 || isCircle) else { return }
        layer.frame = bounds
        layer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: UIRectCorner.allCorners, cornerRadii: isCircle ? bounds.size : CGSize(width: radius, height: radius)).cgPath
    }
}
