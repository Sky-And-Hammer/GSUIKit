//
//  Then.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// 很好用的语法糖
public protocol Then {}

extension Then where Self: Any {
    
    public func with(_ closure:(inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
    
    public func `do`(_ closure:(Self) -> Void) {
        closure(self)
    }
}

extension Then where Self: AnyObject {
    
    public func then(_ closure:(Self) -> Void) -> Self {
        closure(self)
        return self
    }
}

extension NSObject: Then {}
extension CGPoint: Then {}
extension CGRect: Then {}
extension CGSize: Then {}
extension CGVector: Then {}
