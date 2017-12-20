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

/// 标准 1px 的宽度
public var PixelValue: CGFloat {
    return 1 / UIScreen.main.scale
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

// MARK: - UIControl

private var kGSTouchEdgeInset = "\(#file)+\(#line)"
extension UIControl {
    
    /// 点击区域的偏移量
    public var touchEdgeInset: UIEdgeInsets {
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

// MARK: - UITableView

public extension UITableView {
    
    /// 是否可以滚动到底部
    public var canScrollToBotton: Bool { return contentSize.height > bounds.size.height }
    
    /// 当前是否在底部
    public var isAtBottom: Bool { return contentSize.height - bounds.size.height == contentOffset.y }
    
    /// 当前是否在顶部
    public var isAtTop: Bool { return contentOffset.y == 0 }
}

// MARK: - Then

extension Then where Self: UITableViewCell {
    
    
    /// 方便去 给 cell 赋值属性
    /// For example:
    ///     return tableView.dequeueReusableCell(withIdentifier: "HomeContentCell", for: indexPath).then({ (cell: HomeContentCell?) in
    ///         cell?.todo...
    ///     })
    ///
    /// - Parameter closure: 赋值 closure
    public func then<T: UITableViewCell>(_ closure:(T?) -> Void) -> Self {
        closure(self as? T)
        return self
    }
}

extension Then where Self: UICollectionViewCell {
    
    /// 方便去 给 cell 赋值属性
    /// For example:
    ///     return collectionView.dequeueReusableCell(withIdentifier: "HomeContentCell", for: indexPath).then({ (cell: HomeContentCell?) in
    ///         cell?.todo...
    ///     })
    ///
    /// - Parameter closure: 赋值 closure
    public func then<T: UICollectionViewCell>(_ closure:(T?) -> Void) -> Self {
        closure(self as? T)
        return self
    }
}
