//
//  Extensions.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import SnapKit
import GSStability

// MARK: - 计算比例结果

/// UI 在 375 上制作设计图，根据比例计算需要展示时具体尺寸
///
/// - Parameter value: 375 的设计图上 显示尺寸值
/// - Returns:
public func _scale(_ value: CGFloat) -> CGFloat {
    return floor(value / 375.0 * UIScreen.main.bounds.width)
}

// MARK: - UIImage

extension UIImage {
    
    /// 获取纯色图片
    ///
    /// - Parameters:
    ///   - color: 颜色
    ///   - rect: 尺寸
    ///   - radius: 圆角
    /// - Returns:
    public static func image(color: UIColor, rect: CGRect, radius: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: radius, height: radius))
        path.addClip()
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

// MARK: - UIView
extension UIView {
    
    /// 方便去 addsubview 同时配置约束布局条件
    ///
    /// - Parameters:
    ///   - view: 要添加的 subview
    ///   - closure: 约束 closure
    public func _add(_ view: UIView, _ closure: ((ConstraintMaker) -> Void)? = nil) {
        // 如果已经添加到 superview 同时 superview != self， 以防止 'draw(_ rect: CGRect)' 重复调用
        guard view.superview != self else { return }
        view.removeFromSuperview()
        
        self.addSubview(view)
        guard let closure = closure else { return }
        
        view.snp.makeConstraints(closure)
    }
}

// MARK: - UIColor

extension UIColor {
    
    /// 创建 UIColor
    /// For example:
    ///
    ///     let color1 = UIColor(hexString: "FF261B")
    ///     let color2 = UIColor(hexString: "#FF261B")
    ///     let color3 = UIColor(hexString: "FF261BFF")
    ///     let color3 = UIColor(hexString: "#FF261BFF")
    /// - Parameter hexString: 十六进制
    public convenience init(hexString: String) {
        let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        if hexString.hasPrefix("#") { scanner.scanLocation = 1 }
        
        var color: UInt32 = 0
        if scanner.scanHexInt32(&color) { self.init(hex: color, useAlpha: hexString.count > 7) }
        else { self.init(hex: 0x000000) }
    }
    
    /// 创建 UIColor
    ///
    /// - Parameters:
    ///   - hex: 十六进制
    ///   - alphaChannel: 十六进制中是否包括透明
    public convenience init(hex: UInt32, useAlpha alphaChannel: Bool = false) {
        let mask = 0xff
        let r = Int(hex >> (alphaChannel ? 24 : 16)) & mask
        let g = Int(hex >> (alphaChannel ? 16 : 8)) & mask
        let b = Int(hex >> (alphaChannel ? 8 : 0)) & mask
        let a = alphaChannel ? Int(hex) & mask : 255
        
        let red   = CGFloat(r) / 255
        let green = CGFloat(g) / 255
        let blue  = CGFloat(b) / 255
        let alpha = CGFloat(a) / 255
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
// MARK: - Internal

// MARK: - UIControl

private var kGSTouchEdgeInset = "\(#file)+\(#line)"
extension UIControl {
    
    /// 点击区域的偏移量
    var touchEdgeInset: UIEdgeInsets {
        get { return objc_getAssociatedObject(self, &kGSTouchEdgeInset) as? UIEdgeInsets ?? UIEdgeInsets.zero }
        set { objc_setAssociatedObject(self, &kGSTouchEdgeInset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if UIEdgeInsetsEqualToEdgeInsets(touchEdgeInset, UIEdgeInsets.zero) || !isEnabled || !isUserInteractionEnabled || isHidden {
            return super.point(inside: point, with: event)
        }
        
        let relativeFrame = bounds
        let hitFrame = UIEdgeInsetsInsetRect(relativeFrame, touchEdgeInset)
        return hitFrame.contains(point)
    }
}

extension UITableView {
    
    var canScrollToBotton: Bool { return contentSize.height > bounds.size.height }
    
    var isAtBottom: Bool { return contentSize.height - bounds.size.height == contentOffset.y }
    
    var isAtTop: Bool { return contentOffset.y == 0 }
}

// MARK: - Then

extension Then where Self: UITableViewCell {
    
    public func then<T: UITableViewCell>(_ closure:(T?) -> Void) -> Self {
        closure(self as? T)
        return self
    }
}

extension Then where Self: UICollectionViewCell {
    
    public func then<T: UICollectionViewCell>(_ closure:(T?) -> Void) -> Self {
        closure(self as? T)
        return self
    }
}
