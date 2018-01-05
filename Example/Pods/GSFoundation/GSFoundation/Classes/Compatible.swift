//
//  Compatible.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability

// MARK: - Compatible for Foundation
extension String: Compatible {}
extension Date: Compatible {}
extension DispatchQueue: Compatible {}
extension NotificationCenter: Compatible {}


extension GS where Base: NotificationCenter {
    
    @discardableResult
    public func addObserver<T: AnyObject>(_ observer: T, name: Notification.Name, object anObject: AnyObject?, queue: OperationQueue? = OperationQueue.main, handler: @escaping (_ observer: T, _ notification: Notification) -> Void) -> AnyObject {
        let observation = base.addObserver(forName: name, object: anObject, queue: queue) { [unowned observer] noti in handler(observer, noti) }
        GSObserveationRemovr.init(observation).makeRetainBy(observer)
        return observation
    }
}

private class GSObserveationRemovr: NSObject {
    
    let observation: NSObjectProtocol
    
    init(_ obs: NSObjectProtocol) { observation = obs; super.init() }
    
    func makeRetainBy(_ owner: AnyObject) { GS_observationRemoversForObject(owner).add(self) }
    
    deinit { NotificationCenter.default.removeObserver(observation) }
}

private var kGSObservationRemoversForObject = "\(#file)+\(#line)"

private func GS_observationRemoversForObject(_ object: AnyObject) -> NSMutableArray {
    return objc_getAssociatedObject(object, &kGSObservationRemoversForObject) as? NSMutableArray ?? NSMutableArray.init().then {
        objc_setAssociatedObject(object, &kGSObservationRemoversForObject, $0, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}

// MARK: - Public

extension GS where Base: DispatchQueue {
    
    /// 如果在主线程则立刻执行否则异步执行
    public func safeAsync(_ block: @escaping () -> Void) {
        if base === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            base.async {
                block()
            }
        }
    }
}

// MARK: - String

extension GS where Base == String {
    
    /// 长度
    public var length: Int {
        return base.count
    }
    
    /// 是否 URL
    public var isURL: Bool {
        return NSPredicate(format: "SELF MATCHES %@", "(http|https)://([\\w-]+\\.)+[\\w-]+(/[\\w-./?%&=]*)?$").evaluate(with:base)
    }
    
    /// 是否纯数字
    public var isAllDigit: Bool {
        var value: Int = 0
        let scanner = Scanner(string: base)
        return scanner.scanInt(&value) && scanner.isAtEnd
    }
    
    /// 验证字符串长度是否满足条件 使用 ‘>=’ & '<='
    ///
    /// - Parameter tuple: （最小，最大)， -1 为不限
    /// - Returns: 是否满足
    public func check(forLength tuple:(Int, Int)) -> Bool {
        return (tuple.0 == -1 ? true : length >= tuple.0) && (tuple.1 == -1 ? true : length <= tuple.1)
    }
    
    /// 去掉首尾的 空格
    public func trimWhitespace() -> String {
        return base.trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Date

extension GS where Base == Date {
    
    /// 当前时间 + 指定时间
    ///
    /// - Parameters:
    ///   - days: 日
    ///   - hours: 小时
    ///   - minutes: 分钟
    ///   - seconds: 秒
    /// - Returns: 新的时间
    public func add(days: Int = 0, hours: Int = 0, minutes: Int = 0, seconds: Int = 0) -> Date? {
        return NSCalendar.current.date(byAdding: DateComponents(days: days, hours: hours, minutes: minutes, seconds: seconds), to: base)
    }
    
    /// 获取 当\(suffix)毫秒 时间戳
    public static var currentMilliseconds: Int { return Int(Date.init().timeIntervalSince1970 * 1000) }
    
    /// 获取 对应的毫秒时间戳
    public var milliseconds: Int { return Int(base.timeIntervalSince1970 * 1000) }
    
    /// 返回和当前时间比较的文字描述, like '1 天前'， '3 年后'
    public var sinceNowDesc: String {
        let now = Date.init()
        let suffix = base.timeIntervalSince1970 < now.timeIntervalSince1970 ? "前" : "后"
        let components = Calendar.current.dateComponents([.second, .minute, .hour, .day, .weekOfYear, .month, .year], from: base, to: now)
        if let year = components.year, year > 0 { return "\(year) 年\(suffix)"}
        else if let month = components.month, month > 0 { return "\(month) 月\(suffix)" }
        else if let week = components.weekOfYear, week > 0 { return "\(week) 周\(suffix)" }
        else if let day = components.day, day > 0 { return "\(day) 天\(suffix)" }
        else if let hour = components.hour, hour > 0 { return "\(hour) 小时\(suffix)" }
        else if let min = components.minute, min > 0 { return "\(min) 分钟\(suffix)" }
        else if let second = components.second, second >= 3 { return "\(second) 秒\(suffix)" }
        else { return "刚刚" }
    }
    
    /// 获取对应 周几, like '星期日'
    public var weekDesc: String {
        switch Calendar.current.component(Calendar.Component.weekday, from: base) {
        case 0: return "星期日"
        case 1: return "星期一"
        case 2: return "星期二"
        case 3: return "星期三"
        case 4: return "星期四"
        case 5: return "星期五"
        case 6: return "星期六"
        default: return _fatailError(value: String.init()) }
    }
    
    /// 指定 formatter 进行转换
    public func formatDesc(_ formater: DateFormatter) -> String { return formater.string(from: base) }
}
