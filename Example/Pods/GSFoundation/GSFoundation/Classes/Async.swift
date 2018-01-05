//
//  Async.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability

/// 线程枚举
///
/// - main:
/// - userInteractive:
/// - userInitiated:
/// - utility:
/// - background:
/// - custom:
private enum GCD {
    case main, userInteractive, userInitiated, utility, background, custom(queue: DispatchQueue)
    
    var queue: DispatchQueue {
        switch self {
        case .main:
            return .main
        case .userInteractive:
            return .global(qos: .userInteractive)
        case .userInitiated:
            return .global(qos: .userInitiated)
        case .utility:
            return .global(qos: .utility)
        case .background:
            return .global(qos: .background)
        case .custom(let queue):
            return queue
        }
    }
}

public typealias Async = AsyncClosure<Void, Void>

/// <#Description#>
public struct AsyncClosure<In, Out> {
    
    private let workItem: DispatchWorkItem
    private let input:Wrapper<In>?
    private let output_: Wrapper<Out>
    public var output: Out? {
        return output_.value
    }
    
    // MARK: <#mark title#>
    
    private init(_ workItem: DispatchWorkItem, input: Wrapper<In>? = nil, output: Wrapper<Out> = Wrapper()) {
        self.workItem = workItem
        self.input = input
        self.output_ = output
    }
    
    // MARK: <#mark title#>
    
    @discardableResult
    public static func main<O>(after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .main)
    }
    
    @discardableResult
    public static func userInteractive<O>(after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .userInteractive)
    }
    
    @discardableResult
    public static func userInitiated<O>(after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .userInitiated)
    }
    
    @discardableResult
    public static func utility<O>(after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .utility)
    }
    
    @discardableResult
    public static func background<O>(after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .background)
    }
    
    @discardableResult
    public static func custom<O>(queue: DispatchQueue, after seconds: DispatchTimeInterval? = nil, _ closure: @escaping () -> O) -> AsyncClosure<Void, O> {
        return AsyncClosure.async(after: seconds, closure: closure, queue: .custom(queue: queue))
    }
    
    // MARK: <#mark title#>
    
    private static func async<O>(after seconds: DispatchTimeInterval? = nil, closure: @escaping () -> O, queue: GCD) -> AsyncClosure<Void, O> {
        let wrapper = Wrapper<O>()
        let workItem = DispatchWorkItem {
            wrapper.value = closure()
        }
        
        if let seconds = seconds {
            queue.queue.asyncAfter(deadline: .now() + seconds, execute: workItem)
        } else {
            queue.queue.async(execute: workItem)
        }
        
        return AsyncClosure<Void, O>(workItem, output: wrapper)
    }
    
    // MARK: <#mark title#>
    
    @discardableResult
    public func main<O>(after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .main)
    }
    
    @discardableResult
    public func userInteractive<O>(after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .userInteractive)
    }
    
    @discardableResult
    public func userInitiated<O>(after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .userInitiated)
    }
    
    @discardableResult
    public func utility<O>(after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .utility)
    }
    
    @discardableResult
    public func background<O>(after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .background)
    }
    
    @discardableResult
    public func custom<O>(queue: DispatchQueue, after seconds: DispatchTimeInterval? = nil, _ chainingClosure: @escaping (Out) -> O) -> AsyncClosure<Out, O> {
        return chain(after: seconds, chainingClosure: chainingClosure, queue: .custom(queue: queue))
    }
    
    public func cancel() {
        workItem.cancel()
    }
    
    @discardableResult
    public func wait(seconds: DispatchTimeInterval? = nil) -> DispatchTimeoutResult {
        let timeout = seconds.flatMap { DispatchTime.now() + $0 } ?? .distantFuture
        return workItem.wait(timeout: timeout)
    }
    
    // MARK: <#mark title#>
    
    private func chain<O>(after seconds: DispatchTimeInterval? = nil, chainingClosure: @escaping (Out) -> O, queue: GCD) -> AsyncClosure<Out, O> {
        let wrapper = Wrapper<O>()
        let dispatchWorkItem = DispatchWorkItem {
            wrapper.value = chainingClosure(self.output_.value!)
        }
        
        let queue = queue.queue
        if let seconds = seconds {
            workItem.notify(queue: queue) {
                queue.asyncAfter(deadline: .now() + seconds, execute: dispatchWorkItem)
            }
        } else {
            workItem.notify(queue: queue, execute: dispatchWorkItem)
        }
        
        return AsyncClosure<Out, O>(dispatchWorkItem, input: self.output_, output: wrapper)
    }
}

/// <#Description#>
public struct Apply {
    
    public static func userInteractive(_ interations: Int, closure: @escaping (Int) -> ()) {
        GCD.userInteractive.queue.async {
            DispatchQueue.concurrentPerform(iterations: interations, execute: closure)
        }
    }
    
    public static func userInitiated(_ interations: Int, closure: @escaping (Int) -> ()) {
        GCD.userInitiated.queue.async {
            DispatchQueue.concurrentPerform(iterations: interations, execute: closure)
        }
    }
    
    public static func utility(_ interations: Int, closure: @escaping (Int) -> ()) {
        GCD.utility.queue.async {
            DispatchQueue.concurrentPerform(iterations: interations, execute: closure)
        }
    }
    
    public static func background(_ interations: Int, closure: @escaping (Int) -> ()) {
        GCD.background.queue.async {
            DispatchQueue.concurrentPerform(iterations: interations, execute: closure)
        }
    }
    
    public static func custom(queue: DispatchQueue,_ interations: Int, closure: @escaping (Int) -> ()) {
        GCD.custom(queue: queue).queue.async {
            DispatchQueue.concurrentPerform(iterations: interations, execute: closure)
        }
    }
}

/// <#Description#>
public struct AsyncGroup {
    
    private var group: DispatchGroup
    
    public init() {
        group = DispatchGroup()
    }
    
    // MARK: <#mark title#>
    
    private func async(closure: @escaping @convention(block) () -> Swift.Void, queue: GCD) {
        queue.queue.async(group: group, execute: closure)
    }
    
    public func enter() {
        group.enter()
    }
    
    public func leave() {
        group.leave()
    }
    
    // MARK: <#mark title#>
    
    public func main(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .main)
    }
    
    public func userInteractive(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .userInteractive)
    }
    
    public func userInitiated(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .userInitiated)
    }
    
    public func utility(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .utility)
    }
    
    public func background(_ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .background)
    }
    
    public func custom(queue: DispatchQueue, _ closure: @escaping @convention(block) () -> Swift.Void) {
        async(closure: closure, queue: .custom(queue: queue))
    }
    
    @discardableResult
    public func wait(seconds: DispatchTimeInterval? = nil) -> DispatchTimeoutResult {
        let timeout = seconds.flatMap { DispatchTime.now() + $0 } ?? .distantFuture
        return group.wait(timeout: timeout)
    }
}

// MARK: - Extension for `qos_class_t`

/**
 Extension to add description string for each quality of service class.
 */
public extension qos_class_t {
    
    /**
     Description of the `qos_class_t`. E.g. "Main", "User Interactive", etc. for the given Quality of Service class.
     */
    var description: String {
        get {
            switch self {
            case qos_class_main(): return "Main"
            case DispatchQoS.QoSClass.userInteractive.rawValue: return "User Interactive"
            case DispatchQoS.QoSClass.userInitiated.rawValue: return "User Initiated"
            case DispatchQoS.QoSClass.default.rawValue: return "Default"
            case DispatchQoS.QoSClass.utility.rawValue: return "Utility"
            case DispatchQoS.QoSClass.background.rawValue: return "Background"
            case DispatchQoS.QoSClass.unspecified.rawValue: return "Unspecified"
            default: return "Unknown"
            }
        }
    }
}


// MARK: - Extension for `DispatchQueue.GlobalAttributes`

/**
 Extension to add description string for each quality of service class.
 */
public extension DispatchQoS.QoSClass {
    
    var description: String {
        get {
            switch self {
            case DispatchQoS.QoSClass(rawValue: qos_class_main())!: return "Main"
            case .userInteractive: return "User Interactive"
            case .userInitiated: return "User Initiated"
            case .default: return "Default"
            case .utility: return "Utility"
            case .background: return "Background"
            case .unspecified: return "Unspecified"
            }
        }
    }
}
