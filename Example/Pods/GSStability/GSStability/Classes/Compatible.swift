//
//  Compatible.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

// MARK: - 函数调用方法
extension Compatible {
    
    public var gs: GS<Self> { get { return GS(self) } }
}

///  extension 实例方法时使用 gs 的命名空间.
/// For example:
///
///     extension String: Compatible {}
///
///     extension GS where Base == String {
///
///         /// 长度
///         public var length: Int {
///             return base.characters.count
///         }
///     }
public protocol Compatible {
    associatedtype CompatibleType
    var gs: CompatibleType { get }
}

/// 命名空间下实力方法的外层包裹对象
public final class GS<Base> {
    
    /// 被包裹的内容
    public let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}
