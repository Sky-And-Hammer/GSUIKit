//
//  BadgeView.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability

/// - dot: 原点
/// - number: 数字
/// - text: 文本
/// - new: ‘new’
public enum BadgeViewStyle {
    case dot, number, text, new
}

public enum BadgeViewAnimation: String {
    case none
    case scale
    case shake
    case bounce
    case breathe
    
    fileprivate func animateLayer(forLayer layer: CALayer) {
        switch self {
        case .breathe:
            layer.add(CABasicAnimation.init(keyPath: "opacity").then {
                $0.fromValue = 1
                $0.toValue = 0.1
                $0.autoreverses = true
                $0.repeatCount = Float.greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
                $0.duration = 1.2
                $0.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionLinear)
                $0.fillMode = kCAFillModeForwards
            }, forKey: rawValue)
        case .bounce:
            let hOffset = layer.bounds.size.height / 4
            layer.add(CAKeyframeAnimation.init(keyPath: "transform").then {
                $0.values = [CATransform3DMakeScale(0, 0, 0),
                             CATransform3DMakeScale(0, -hOffset, 0),
                             CATransform3DMakeScale(0, 0, 0),
                             CATransform3DMakeScale(0, hOffset, 0),
                             CATransform3DMakeScale(0, 0, 0)]
                $0.repeatCount = Float.greatestFiniteMagnitude
                $0.duration = 0.8
                $0.fillMode = kCAFillModeForwards
            }, forKey: rawValue)
        case .scale:
            layer.add(CABasicAnimation.init(keyPath: "transform.scale").then {
                $0.fromValue = 1.2
                $0.toValue = 0.8
                $0.duration = 0.8
                $0.autoreverses = true
                $0.repeatCount = Float.greatestFiniteMagnitude
                $0.isRemovedOnCompletion = false
                $0.fillMode = kCAFillModeForwards
            }, forKey: rawValue)
        case .shake:
            let hOffset = layer.bounds.size.height / 4
            layer.add(CAKeyframeAnimation.init(keyPath: "transform").then {
                $0.values = [CATransform3DMakeTranslation(0, 0, 0),
                             CATransform3DMakeTranslation(-hOffset, 0, 0),
                             CATransform3DMakeTranslation(0, 0, 0),
                             CATransform3DMakeTranslation(hOffset, 0, 0),
                             CATransform3DMakeTranslation(0, 0, 0)]
                $0.repeatCount = Float.greatestFiniteMagnitude
                $0.duration = 0.8
                $0.fillMode = kCAFillModeForwards
            }, forKey: rawValue)
        case .none: layer.removeAllAnimations()
        }
    }
}

// MARK: - BadgeView

public class BadgeView: UILabel {
    
    /// <#Description#>
    open var limitNumber = 99
    /// <#Description#>
    open var hideOnZero = true
    /// <#Description#>
    open var scaleContent = false
    /// <#Description#>
    open var style = BadgeViewStyle.dot { didSet { text = _textStorage } }
    /// <#Description#>
    open var animation = BadgeViewAnimation.none { didSet { animation.animateLayer(forLayer: layer) } }
    /// <#Description#>
    open var minSize = CGSize.init(width: 12, height: 12) { didSet { sizeToFit(); text = _textStorage } }
    /// <#Description#>
    open var offsets: CGPoint! = nil {
        didSet {
            if oldValue == nil { snp.makeConstraints { $0.center.equalTo(offsets) }
            } else { snp.updateConstraints { $0.center.equalTo(offsets) } }
        }
    }
    
    public override var text: String? {
        get { return super.text }
        set {
            _textStorage = newValue ?? ""
            switch style {
            case .new:
                super.text = "new"
            case .text:
                super.text = _textStorage
            case .number:
                guard let value = Int(_textStorage) else { return }
                if value > limitNumber { super.text = "\(limitNumber)+" }
                else { super.text = "\(_textStorage)" }
            default:
                super.text = _textStorage
            }
            
            sizeToFit()
            layer.cornerRadius = bounds.height / 2
            layer.masksToBounds = true
            
            snp.updateConstraints {
                $0.width.equalTo(bounds.width)
                $0.height.equalTo(bounds.height)
            }
            setNeedsLayout()
            
            if visible && scaleContent { show(animated: true) }
            
            guard let text = self.text else { return }
            if hideOnZero {
                switch style {
                case .number:
                    guard let value = Int(text) else { return }
                    isHidden = value == 0
                case .text:
                    isHidden = text.isEmpty
                default: break
                }
            } else { isHidden = false }
        }
    }
    
    fileprivate var _textStorage = ""
    fileprivate var visible: Bool {
        return superview != nil && !isHidden && alpha > 0
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.do {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.textColor = UIColor.white
            $0.font = UIFont.systemFont(ofSize: 12)
            $0.textAlignment = .center
            $0.backgroundColor = UIColor.red
            $0.snp.makeConstraints {
                $0.width.equalTo(frame.width)
                $0.height.equalTo(frame.height)
            }
        }
    }
    
    convenience init() { self.init(frame: CGRect.zero) }
    required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        var suitSize = super.sizeThatFits(size)
        suitSize.height = max(suitSize.height, minSize.height)
        suitSize.width = max(max(suitSize.width + suitSize.height / 2, minSize.width), suitSize.height)
        return suitSize
    }
    
    func show(animated: Bool) {
        alpha = 1
        transform = CGAffineTransform.init(scaleX: 0, y: 0)
        if animated {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.6, options: [.allowAnimatedContent], animations: { [unowned self] in
                self.transform = CGAffineTransform.identity
                }, completion: { (_) in })
        } else { transform = CGAffineTransform.identity }
    }
    
    func hide(animated: Bool) {
        if animated {
            UIView.animate(withDuration: 0.35, animations: {
                self.alpha = 0
            }, completion: { (_) in
                self.removeFromSuperview()
            })
        } else { removeFromSuperview() }
    }
}

// MARK: - UIView

private var kSJBBadgeView = "\(#file)+\(#line)"

extension UIView {
    
    public var badgeView: BadgeView {
        get {
            guard !(self is BadgeView) else { fatalError("You can not add a badge in badge!!!") }
            
            if let value = objc_getAssociatedObject(self, &kSJBBadgeView) as? BadgeView { return value }
            else {
                return BadgeView.init().then {
                    _add($0)
                    
                    bringSubview(toFront: $0)
                    self.badgeView = $0
                }
            }
            
        }
        
        set { objc_setAssociatedObject(self, &kSJBBadgeView, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
}

// MARK: - Badgeable

public protocol Badgeable {
    
    var containerView: UIView { get }
    
    func assmbilingBadge(_ closure: (BadgeView) -> Void)
    func showBadge(animated: Bool)
    func hideBadge(animated: Bool)
}

public extension Badgeable {
    
    func assmbilingBadge(_ closure: (BadgeView) -> Void) { closure(containerView.badgeView) }
    func showBadge(animated: Bool) { containerView.badgeView.show(animated: animated) }
    func hideBadge(animated: Bool) { containerView.badgeView.hide(animated: animated) }
}

// MARK: - Badgeable & UIView

extension UIView: Badgeable {
    
    public var containerView: UIView { return self }
}

// MARK: - Badgeable & UITabbarItem

extension UITabBarItem: Compatible {}
extension UITabBarItem: Badgeable {
    public var containerView: UIView {
        let tabBarButton = value(forKey: "_view") as? UIView ?? UIView()
        for view in tabBarButton.subviews {
            if let clazz = view.superclass {
                if NSStringFromClass(clazz) == "UIImageView" { return view }
            }
        }
        
        return tabBarButton
    }
}

// MARK: - Badgeable & UINavigationItem

extension UINavigationItem: Compatible {}
extension UINavigationItem: Badgeable {
    
    public var containerView: UIView {
        let navigationButton = value(forKey: "_view") as? UIView ?? UIView()
        for view in navigationButton.subviews {
            if #available(iOS 11.0, *) {
                if view.isKind(of: UIButton.self) {
                    view.layer.masksToBounds = false
                    return view
                }
            } else {
                if view.isKind(of: UIImageView.self) {
                    view.layer.masksToBounds = false
                    return view
                }
            }
        }
        
        return navigationButton
    }
}


