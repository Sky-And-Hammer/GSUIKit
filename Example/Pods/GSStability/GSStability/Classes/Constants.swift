//
//  Constants.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// 需要使用并不可修改的常量对象
/// For example:
///
///     extension Constant {
///
///         public static let appID = Constant(rawValue: "2222")
///         public static let scheme = Constant(rawValue: "shijiebang")
///     }
public struct Constant: RawRepresentable {
    
    public var rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}
