//
//  Extensions.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

// MARK: - FatalError

/// <#Description#>
///
/// - Parameters:
///   - msg: <#msg description#>
///   - value: <#value description#>
/// - Returns: <#return value description#>
/// - Throws: <#throws value description#>
public func _fatailError<T>(_ msg: String = "调用有问题，正常不应该执行这里", value: @autoclosure () throws -> T) rethrows -> T {
    #if DEBUG
        fatalError(msg)
    #else
        return try value()
    #endif
}

// MARK: - Public

// MARK: - String

public extension Array {
    
    /// 安全获取数组中数据 防止越界
    ///
    /// - Parameter index: 越界会返回 nil
    public subscript(gs index: Int) -> Element? {
        return count > index ? self[index] : nil
    }
    
    /// 安全获取数组中数据 防止越界
    ///
    /// - Parameter bounds: 越界会返回 []
    public subscript(gs bounds: Range<Int>) -> ArraySlice<Element> {
        return bounds.lowerBound > -1 && bounds.upperBound < count ? self[bounds] : []
    }
}


// MARK: - Bundle

public extension Bundle {
    
    /// app 打包环境
    static var appChannel: String {
        #if DEBUG
            return "Beta"
        #else
            return isInHouse ? "In-House" : "AppStore"
        #endif
    }
    
    /// 版本号
    static var shortVersion: String {
        return main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    /// build 版本号
    static var buildVersion: String {
        return main.infoDictionary?[kCFBundleVersionKey as String] as? String ?? ""
    }
    
    /// bundle ID
    static var identifier: String {
        return main.bundleIdentifier ?? ""
    }
    
    /// 是否 In-House 版本
    static var isInHouse: Bool {
        return main.bundleIdentifier?.contains("inhouse") ?? false
    }
    
    /// app 显示名
    static var displayName: String {
        return "\(main.object(forInfoDictionaryKey: "CFBundleDisplayName") ?? "")"
    }
    
    /// 'displayName' V'shortVersion'
    public static var appVersion: String {
        return "\(displayName) V\(shortVersion)"
    }
}

// MARK: - DispatchQueue
public extension DispatchQueue {
    
    private static var _onceTracker = [String]()
    
    /// 执行一次
    ///
    /// - Parameters:
    ///   - token: 标示 token
    ///   - block: 执行 closur
    static func once(token: String, block: ()-> Void) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        
        guard !_onceTracker.contains(token) else {
            return
        }
        
        _onceTracker.append(token)
        block()
    }
}

// MARK: - Internal

// MARK: - DateComponents

extension DateComponents {
    
    init(days: Int, hours: Int, minutes: Int, seconds: Int) {
        self.init()
        self.day = days
        self.hour = hours
        self.minute = minutes
        self.second = seconds
    }
}

