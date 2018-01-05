//
//  MethodSwizzle.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// 方法替换结果
///
/// - succeed: 成功
/// - originMethodNotFound: 未找到原方法
/// - alternateMethodNotFound: 未找到替换方法
public enum SwizzleResult {
    case Succeed
    case OriginMethodNotFound
    case AlternateMethodNotFound
}

public extension NSObject {
    
    @discardableResult
    public class func swizzleInstanceMethod(origSelector: Selector,
                                            toAlterSelector alterSelector: Selector) -> SwizzleResult {
        return self.swizzleMethod(origSelector: origSelector,
                                  toAlterSelector: alterSelector,
                                  inAlterClass: self.classForCoder(),
                                  isClassMethod: false)
    }
    
    @discardableResult
    public class func swizzleClassMethod(origSelector: Selector,
                                         toAlterSelector alterSelector: Selector) -> SwizzleResult {
        return self.swizzleMethod(origSelector: origSelector,
                                  toAlterSelector: alterSelector,
                                  inAlterClass: self.classForCoder(),
                                  isClassMethod: true)
    }
    
    @discardableResult
    public class func swizzleInstanceMethod(origSelector: Selector,
                                            toAlterSelector alterSelector: Selector,
                                            inAlterClass alterClass: AnyClass) -> SwizzleResult {
        return self.swizzleMethod(origSelector: origSelector,
                                  toAlterSelector: alterSelector,
                                  inAlterClass: alterClass,
                                  isClassMethod: false)
    }
    
    @discardableResult
    public class func swizzleClassMethod(origSelector: Selector,
                                         toAlterSelector alterSelector: Selector,
                                         inAlterClass alterClass: AnyClass) -> SwizzleResult {
        return self.swizzleMethod(origSelector: origSelector,
                                  toAlterSelector: alterSelector,
                                  inAlterClass: alterClass,
                                  isClassMethod: true)
    }
    
    @discardableResult
    private class func swizzleMethod(origSelector: Selector,
                                     toAlterSelector alterSelector: Selector!,
                                     inAlterClass alterClass: AnyClass!,
                                     isClassMethod:Bool) -> SwizzleResult {
        
        var alterClass: AnyClass? = alterClass
        var origClass: AnyClass = self.classForCoder()
        if isClassMethod {
            alterClass = object_getClass(alterClass)
            origClass = object_getClass(self.classForCoder())!
        }
        
        return SwizzleMethod(origClass: origClass, origSelector: origSelector, toAlterSelector: alterSelector, inAlterClass: alterClass)
    }
}

private func SwizzleMethod(origClass:AnyClass!,origSelector: Selector,toAlterSelector alterSelector: Selector!,inAlterClass alterClass: AnyClass!) -> SwizzleResult{
    
    guard  let origMethod: Method = class_getInstanceMethod(origClass, origSelector) else {
        return SwizzleResult.OriginMethodNotFound
    }
    
    guard let altMethod: Method = class_getInstanceMethod(alterClass, alterSelector) else {
        return SwizzleResult.AlternateMethodNotFound
    }
    
    
    
    _ = class_addMethod(origClass,
                        origSelector,method_getImplementation(origMethod),
                        method_getTypeEncoding(origMethod))
    
    
    _ = class_addMethod(alterClass,
                        alterSelector,method_getImplementation(altMethod),
                        method_getTypeEncoding(altMethod))
    
    method_exchangeImplementations(origMethod, altMethod)
    
    return SwizzleResult.Succeed
    
}

