//
//  NavigationBarItem.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

// MARK: - NavigationBarItem

/// NavigationBarItem
public struct NavigationBarItem: Hashable {
    
    /// 显示图片 显示优先级高
    public var imageName: String?
    
    /// 显示文字 显示优先级中
    public var title: String?
    public var titleColor: UIColor?
    public var titleFont: UIFont?
    
    
    /// 点击的 selector 执行优先级低
    public var selector: Selector?
    
    /// 点击的执行闭包 执行优先级高
    public var closure: (() -> Void)?
    
    
    /// 自定义view 显示优先级最高
    public var customView: UIView?
    
    /// 最终对应的 barItem
    public var barItem: UIBarButtonItem?
    
    public var hashValue: Int {
        return (imageName ?? "").hashValue + (title ?? "").hashValue + (customView?.hash ?? 0)
    }
    
    public init(selector: Selector?, title: String? = nil, imageName: String? = nil ) {
        self.selector = selector
        self.title = title
        self.imageName = imageName
    }
    
    public init(closure: (() -> Void)?, title: String? = nil, imageName: String? = nil ) {
        self.closure = closure
        self.title = title
        self.imageName = imageName
    }
    
    public init(selector: Selector?, customView: UIView) {
        self.selector = selector
        self.customView = customView
    }
    
    public init(closure: (() -> Void)?, customView: UIView) {
        self.closure = closure
        self.customView = customView
    }
    
    mutating internal func setItem(item: UIBarButtonItem) {
        self.barItem = item
    }
}

// MARK: - Hashable

public func ==(lhs: NavigationBarItem, rhs: NavigationBarItem) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

// MARK: - CustomBarItemable

public protocol CustomBarItemable: class {
    
    var leftItems: [NavigationBarItem] { get set }
    var rightItems: [NavigationBarItem] { get set }
}

extension CustomBarItemable {
    
    public var leftItems: [NavigationBarItem] { return [] }
    public var rightItems: [NavigationBarItem] { return [] }
}

// MARK: - UINavigationBar Extensions

extension UINavigationBar {
    
    /// 修改了 iOS11 后 navgationBarContentView 的 margin。使 items 贴边
    @objc func _marginLayoutSubviews() {
        _marginLayoutSubviews()
        
        layoutMargins = UIEdgeInsets.zero
        subviews.forEach {
            if NSStringFromClass($0.classForCoder).contains("ContentView") {
                $0.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            }
        }
    }
}

// MARK: - UIViewController & CustomBarItemable

extension CustomBarItemable where Self: UIViewController {
    
    /// 根据 ‘CustomBarItemable’ 装载需要显示的 barItem
    public func installItems() {
        guard let _ = navigationController else { return }
        
        if #available(iOS 11.0, *) {
            DispatchQueue.once(token: "CustomBarItemable") {
                UINavigationBar.swizzleInstanceMethod(origSelector: #selector(UINavigationBar.layoutSubviews), toAlterSelector: #selector(UINavigationBar._marginLayoutSubviews))
            }
        }
        
        // left
        cleanBarItem(isRight: false)
        let list = _itemTranslate(items: &self.leftItems, isRight: false)
        if #available(iOS 11.0, *) {
            navigationItem.leftBarButtonItems = list
        } else {
            navigationItem.leftBarButtonItems = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil).then {
                $0.width = -8
                }] + list
        }
        
        
        cleanBarItem(isRight: true)
        let list2 = _itemTranslate(items: &self.rightItems, isRight: true)
        if #available(iOS 11.0, *) {
            navigationItem.rightBarButtonItems = list2
        } else {
            navigationItem.rightBarButtonItems = [UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil).then {
                $0.width = -8
                }] + list2
        }
    }
    
    private func _itemTranslate(items: inout [NavigationBarItem], isRight: Bool = true) -> [UIBarButtonItem] {
        return items.enumerated().map { offset, item in
            let button = BarItemButton().then {
                $0.frame = CGRect(x: 0, y: 0, width: 30, height: 34)
                if let imageName = item.imageName, let image = UIImage(named: imageName) {
                    $0.setImage(image, for: .normal)
                } else {
                    $0.setTitle(item.title, for: .normal)
                    $0.setTitleColor(item.titleColor, for: .normal)
                    $0.titleLabel?.font = item.titleFont
                }
                
                if offset > 0 {
                    // 修改图片的偏移量 和 点击区域的偏移量
                    $0.imageEdgeInsets = UIEdgeInsets(top: 0, left: CGFloat(offset * (isRight ? 8 : -8)), bottom: 0, right: CGFloat(offset * (isRight ? -8 : 8)))
                    $0.touchEdgeInset = UIEdgeInsets(top: 0, left: CGFloat(offset * (isRight ? 8 : -8)), bottom: 0, right: CGFloat(offset * (isRight ? -8 : 8)))
                }
                
                if let closure = item.closure {
                    $0.closure = closure
                } else if let selector = item.selector {
                    $0.addTarget(self, action: selector, for: .touchUpInside)
                }
            }
            
            let barItem = UIBarButtonItem(customView: button)
            items[offset].setItem(item: barItem)
            
            return barItem
        }
    }
    
    /// 清除 bar item 上所有按钮
    ///
    /// - Parameter isRight:
    public func cleanBarItem(isRight: Bool) {
        if isRight {
            navigationItem.rightBarButtonItem = nil
            navigationItem.rightBarButtonItems = nil
        } else {
            navigationItem.hidesBackButton = true
            navigationItem.leftBarButtonItem = nil
            navigationItem.leftBarButtonItems = nil
        }
    }
}

class BarItemButton: UIButton {
    
    var closure: (() -> Void)? = nil {
        didSet {
            guard let _ = closure else { return }
            addTarget(self, action: #selector(tapForClosure), for: .touchUpInside)
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapForClosure() {
        closure?()
    }
}
