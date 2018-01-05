//
//  Wrapper.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// Swift weak 对象使用 wrapper 包裹一层
/// For example:
///
///     let a = Wrapper(ObjectA())
public class Wrapper<T> {
    public var value: T?
    
    public init(_ value: T? = nil) { self.value = value }
}

public struct WeakWrapper<T: AnyObject> {
    public weak var value: T?
    
    public init(_ value: T? = nil) { self.value = value }
}
