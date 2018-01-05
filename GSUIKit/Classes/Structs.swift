//
//  Structs.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// 常用颜色
/// For example:
///
///     public static let disabled = UIColor(hexString: "DFDFDF")
///     public struct View {
///          public static let backgroudDefault = UIColor(hexString: "EDEDED")
///     }
public struct Colors {}

/// 图片
/// For example:
///
///     public static var navCloseImage = ""
///     public struct View {
///          public static var navCloseImage = ""
///     }
public struct Images {}

/// 字体
/// For example:
///
///     public static let defaultFontName = ""
///     public static func defalut(size: CGFloat, bold: Bool = false) -> UIFont {
///          return _font(fontName: defaultFontName, size: size, isBlod: bold)
///     }
public struct Fonts {
    
    public static func _font(fontName: String, size: CGFloat, isBlod: Bool) -> UIFont {
        return UIFont.init(name: fontName, size: size) ?? (isBlod ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size))
    }
}
