//
//  Hudable.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSFoundation
import GSStability
import SnapKit

// MARK: - Hudable

/// protocol for hud view
public protocol Hudable {}

extension Hudable {
    
    /// 指定 HUDContentType 进行展示，超时后自动消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - onView: 承载的view， nil 的时候为最上层
    ///   - delay: 显示时间，默认为2秒
    ///   - completed: 完成后的回调
    public func flash(_ type: HUDContentType, onView: UIView?, delay: DispatchTimeInterval = .seconds(2), completed: ((Bool) -> Void)? = nil) {
        Self.flash(type, onView: onView, delay: delay, completed: completed)
    }
    
    /// 指定 HUDContentType 进行展示
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - view: 承载的view， nil 的时候为最上层
    public func show(_ type: @autoclosure () -> HUDContentType, onView view: UIView?) {
        Self.show(type(), onView: view)
    }
    
    /// HUD 消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - animated: 是否有动画
    ///   - completed: 完成后的回调
    public func hide(_ type: @autoclosure () -> HUDContentType, animated: Bool = true, completed: ((Bool) -> Void)? = nil) {
        Self.hide(type(), animated: animated, completed: completed)
    }
    
    /// HUD 超时后自动消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - delay: 显示时间，默认为2秒
    ///   - completed: 完成后的回调
    public func delayHide(_ type: @autoclosure () -> HUDContentType, delay: DispatchTimeInterval = .seconds(2), completed: ((Bool) -> Void)? = nil ) {
        Self.hide(type(), delay: delay, completed: completed)
    }
    
    /// 指定 HUDContentType 进行展示，超时后自动消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - onView: 承载的view， nil 的时候为最上层
    ///   - delay: 显示时间，默认为2秒
    ///   - completed: 完成后的回调
    public static func flash(_ type: HUDContentType, onView: UIView?, delay: DispatchTimeInterval = .seconds(2), completed: ((Bool) -> Void)? = nil) {
        show(type, onView: onView)
        hide(type, delay: delay, completed: completed)
    }
    
    /// 指定 HUDContentType 进行展示
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - view: 承载的view， nil 的时候为最上层
    public static func show(_ type: @autoclosure () -> HUDContentType, onView view: UIView?) {
        let value = type()
        SJBHud.share.show(value, onView: view)
        if let duration = value.isAutoDissmiss?() {
            hide(value, delay: duration, completed: nil)
        }
    }
    
    /// HUD 消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - animated: 是否有动画
    ///   - completed: 完成后的回调
    public static func hide(_ type: @autoclosure () -> HUDContentType, animated: Bool = true, completed: ((Bool) -> Void)? = nil) {
        SJBHud.share.hide(type(), animated: animated, completed: completed)
    }
    
    /// HUD 超时后自动消失
    ///
    /// - Parameters:
    ///   - type: HUDContentType
    ///   - delay: 显示时间，默认为2秒
    ///   - completed: 完成后的回调
    public static func hide(_ type: @autoclosure () -> HUDContentType, delay: DispatchTimeInterval = .seconds(2), completed: ((Bool) -> Void)? = nil ) {
        SJBHud.share.hide(type(), delay: delay, completed: completed)
    }
}

// MARK: - HUDContentType

/// 展示 hud 的数据源
public class HUDContentType: Hashable {
    
    public var hashValue: Int {
        return identifier.hashValue
    }
    
    public var rawValue: UIView
    
    /// (ConstraintMaker, container view)
    /// hud content view 与 对应 HUDContainer 约束条件设置闭包.
    /// 直接展示的话 设置 约束条件就可以，如果需要出现动画，则需直接指定 frame，同时 subviews 也不可以使用自动布局
    public var constraintClosure: ((ConstraintMaker, UIView) -> Void) = { _,_  in }
    
    /// hud container 的背景色
    public var targetColor = UIColor(white: 0, alpha: 0.25)
    
    /// 是否允许用户点击
    public var isUserInteractionEnabled = false
    
    /// 是否点击后自动消失
    public var isAutoDissmissByTouch = true
    
    /// 是否自动消失
    public var isAutoDissmiss: (() -> DispatchTimeInterval)? = nil
    
    /// 显示的动画时间
    public var appearDuration = 0.25
    
    /// 显示的 hud 自定义闭包
    public var appearClosure: ((UIView) -> Void)?
    
    /// app恢复前台后调用
    public var retryAppearClosure: (() -> Void)?
    
    /// 消失的动画时间
    public var disappearDuration = 0.3
    
    /// 消失的 hud 自定义闭包
    public var disappearClosure: ((UIView) -> Void)?
    
    /// 点击后的闭包
    public var touchClosure: () -> Void = {}
    
    private var identifier: String
    
    /// init 方法.
    /// For example:
    ///
    ///     public static let indicator = HUDContentType(rawValue: HudIndicatorView(), identifier: HudIndicatorView.description()).then {
    ///         $0.isUserInteractionEnabled = false
    ///         $0.targetColor = UIColor(hexString: "eeeeee")
    ///         $0.appearClosure = {
    ///             guard let view = $0 as? HudIndicatorView else { return }
    ///             view.indicatorView.startAnimating()
    ///             view.alpha = 1
    ///         }
    ///         $0.disappearClosure = {
    ///             guard let view = $0 as? HudIndicatorView else { return }
    ///             view.indicatorView.stopAnimating()
    ///             view.alpha = 0
    ///         }
    ///         $0.constraintClosure = {
    ///             $0.center.equalToSuperview()
    ///             $0.width.height.equalTo(_scale(50))
    ///         }
    ///     }
    ///
    /// - Parameters:
    ///   - rawValue:
    ///   - identifier: 相同 identifier 的同时只允许显示一个
    public init(rawValue: @autoclosure @escaping () -> UIView, identifier: String) {
        self.rawValue = rawValue()
        self.identifier = identifier
    }
}

extension HUDContentType: Then {
    
    public func then(_ closure:(HUDContentType) -> Void) -> HUDContentType {
        closure(self)
        return self
    }
}

public func ==(lhs: HUDContentType, rhs: HUDContentType) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - SJBHud
/// Hud 单例对象

final class SJBHud {
    
    static let share = SJBHud()
    
    private var lock = NSLock()
    private var containers: [HUDContentType: (HUDContainer, GSTimer?)] = [:]
    subscript (type: HUDContentType) -> (HUDContainer, GSTimer?)? {
        get {
            lock.lock(); defer { lock.unlock() }
            return containers[type]
        }
        set {
            lock.lock(); defer { lock.unlock() }
            containers[type] = newValue
        }
    }
    
    private init() {
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { (_) in
            self.containers.forEach {
                $0.value.0.retryAppear()
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func show(_ type: HUDContentType, onView: UIView?) {
        guard let view = onView ?? UIApplication.shared.keyWindow else { print("找不到承载的 view"); return }
        
        let tuple = containers[type] ?? (HUDContainer(type: type), nil)
        guard !view.subviews.contains(tuple.0) && tuple.0.superview == nil else {
            print("已有一个当前类型的 hud 在承载 view 上显示状态 || 有一个当前类型的 hud 展示在其他承载 view 上"); return
        }
        
        containers[type] = tuple
        view.gs.add(tuple.0.then {
            $0.backgroundColor = UIColor.clear
        }) {
            $0.top.equalToSuperview().offset(view.bounds.origin.y)
            $0.leading.equalToSuperview().offset(view.bounds.origin.x)
            $0.width.equalTo(view.bounds.size.width)
            $0.height.equalTo(view.bounds.size.height)
        }
        
        tuple.0.show()
    }
    
    func hide(_ type: HUDContentType, animated: Bool, completed:((Bool) -> Void)?) {
        containers[type]?.0.hide(animated: animated, complated: completed)
        containers[type] = nil
    }
    
    func hide(_ type: HUDContentType, delay: DispatchTimeInterval, completed: ((Bool) -> Void)?) {
        containers[type]?.1 = GSTimer(interval: delay) { _ in
            self.hide(type, animated: true, completed: completed)
        }
        
        self.containers[type]?.1?.start()
    }
}

// MARK: - HUDContainer
/// 每一个 hud 对应的承载 container

final class HUDContainer: UIView {
    
    var contentView: UIView {
        get { return _contnet }
        set {
            _contnet.removeFromSuperview()
            _contnet = newValue
            gs.add(_contnet) {
                self.type.constraintClosure($0, self)
                
            }
        }
    }
    
    var type: HUDContentType
    
    private var _contnet = UIView()
    private var alreadyShow = false
    
    init(type: HUDContentType) {
        self.type = type
        super.init(frame: CGRect.zero)
        self.contentView = type.rawValue
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.first?.view == self {
            if type.isUserInteractionEnabled {
                if type.isAutoDissmissByTouch {
                    SJBHud.share.hide(type, animated: true, completed: nil)
                } else {
                    type.touchClosure()
                }
            }
        } else {
            super.touchesBegan(touches, with: event)
        }
    }
    
    func show() {
        self.alreadyShow = true
        UIView.animate(withDuration: type.appearDuration, animations: {
            self.backgroundColor = self.type.targetColor
            self.type.appearClosure?(self.type.rawValue)
        }) { (_) in
            
        }
    }
    
    func hide(animated: Bool, complated: ((Bool) -> Void)?) {
        guard alreadyShow else { return }
        UIView.animate(withDuration: type.disappearDuration, animations: {
            self.backgroundColor = UIColor.clear
            self.type.disappearClosure?(self.type.rawValue)
        }) { (finished) in
            self.alreadyShow = true
            self.removeFromSuperview()
            complated?(finished)
        }
    }
    
    func retryAppear() {
        if alreadyShow {
            type.retryAppearClosure?()
        }
    }
}

