//
//  Compatible.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import GSStability
import GSFoundation
import SnapKit

// MARK: - Compatible for UIResponder

extension UIResponder: Compatible {}

// MARK: - UIViewController

extension GS where Base: UIViewController {
    
    /// 适配 scrollview 的顶部空白
    public func adjustInset(_ scrollView: UIScrollView? = nil) {
        if #available(iOS 11.0, *) { scrollView?.contentInsetAdjustmentBehavior = .never }
        else { base.automaticallyAdjustsScrollViewInsets = false }
    }
    
    /// like UIViewController.push
    ///
    /// - Note: 如果本身没有 navigationController 会执行 'present(viewController:animated:completion:)'
    ///
    /// - Parameters:
    ///   - viewController: source viewController
    public func push(viewController: UIViewController?, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if let controller = viewController {
            if let navigationController = (base as? UINavigationController) ?? (base.navigationController) {
                navigationController.pushViewController(controller.then { $0.hidesBottomBarWhenPushed = true }, animated: animated)
                completion?(true)
            } else { present(viewController: controller, animated: true, completion: completion)}
        } else { completion?(false) }
    }
    
    /// like UIViewController.present
    ///
    /// - Parameters:
    ///   - viewController: source viewController
    public func present(viewController: UIViewController?, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        if let controller = viewController { base.present(controller, animated: animated) { completion?(true) } }
        else { completion?(false) }
    }
    
    /// like UIViewController.popViewController
    ///
    /// - Note: 如果本身没有 navigationController 会执行 'dismiss(animated:completion:)'
    public func popSelf(animated: Bool) {
        guard let navigationController = base.navigationController else { return  dismiss(animated: animated) }
        navigationController.popViewController(animated: animated)
    }
    
    /// like UIViewController.dismiss
    public func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        base.dismiss(animated: animated, completion: completion)
    }
    
    
}


// MARK: - UIView

extension GS where Base: UIView {
    
    /// 方便去 addsubview 同时配置约束布局条件
    ///
    /// - Parameters:
    ///   - view: 要添加的 subview
    ///   - closure: 约束 closure
    public func add(_ view: UIView, _ closure: ((ConstraintMaker) -> Void)? = nil) {
        // 如果已经添加到 superview 同时 superview != self， 以防止 'draw(_ rect: CGRect)' 重复调用
        guard view.superview != base else { return }
        view.removeFromSuperview()
        
        base.addSubview(view)
        guard let closure = closure else { return }
        
        view.snp.makeConstraints(closure)
    }
    
    /// 删除 view 的subview
    ///
    /// - Parameter closure: 是否删除的闭包判断
    public func removeSubviews(_ closure: ((UIView) -> Bool)? = nil) { base.subviews.forEach { if closure?($0) ?? true { $0.removeFromSuperview() } } }
    
    /// 添加点击事件
    public func whenTap(_ closure: @escaping () -> Void) {
        guard (base.gestureRecognizers?.filter { $0.isKind(of: _GSTapGestureRecognizer.self) } ?? []).count == 0 else { return }
        let gesture = _GSTapGestureRecognizer.init { (_, state, _) in if state == .recognized { closure() } }.then {
            $0.numberOfTouchesRequired = 1
            $0.numberOfTapsRequired = 1
        }
        
        base.gestureRecognizers?.forEach {
            guard let tap = $0 as? UITapGestureRecognizer else { return }
            if tap.numberOfTapsRequired == gesture.numberOfTapsRequired
                && tap.numberOfTouchesRequired == gesture.numberOfTouchesRequired {
                gesture.require(toFail: tap)
            }
        }
        
        base.addGestureRecognizer(gesture)
    }
    
    final class _GSTapGestureRecognizer: UITapGestureRecognizer {
        
        var allowHandler = false
        var handler: (UIGestureRecognizer, UIGestureRecognizerState, CGPoint) -> Void
        
        init(handler: @escaping (UIGestureRecognizer, UIGestureRecognizerState, CGPoint) -> Void) {
            self.handler = handler
            super.init(target: self, action: #selector(handleAction(_:)))
        }
        
        @objc func handleAction(_ sender: UIGestureRecognizer) {
            guard  allowHandler else { return }
            
            handler(sender, sender.state, self.location(in: self.view))
        }
    }
}

// MARK: - UITableView

extension GS where Base: UITableView {
    
    /// tableView 在 cell 较少时，可以隐藏空白 cell 的线条
    public func hiddenExtraCellLine() { base.tableFooterView = UIView().then{ $0.backgroundColor = UIColor.clear } }
    
    /// UITableView 使用中业务逻辑后需要的话。可以使用此方法返回 空的 cell，以保证 debug 的时候逻辑没有问题
    public func emptyCell() -> UITableViewCell { return _fatailError("cell 数据有问题，不应该调用这里的", value: UITableViewCell.init()) }
    
    /// 滚动至顶部
    ///
    /// - Parameter animated: 是否 动态
    public func scrollToTop(animated: Bool) { if !base.isAtTop { base.setContentOffset(CGPoint.zero, animated: animated) } }
    
    /// 滚动至底部
    ///
    /// - Parameter animated: 是否 动态
    public func scrollToButton(animated: Bool) {
        if base.canScrollToBotton && !base.isAtBottom { base.setContentOffset(CGPoint.init(x: 0, y: base.contentSize.height - base.bounds.size.height), animated: animated) }
    }
    
    /// 停止滚动
    public func stopScrolling() {
        guard  base.isDragging else { return }
        
        var offset = base.contentOffset
        offset.y -= 1
        base.setContentOffset(offset, animated: false)
        offset.y += 1
        base.setContentOffset(offset, animated: false)
    }
}

// MARK: - UITableView

extension GS where Base: UICollectionView {
    
    /// UICollectionView 使用中业务逻辑后需要的话。可以使用此方法返回 空的 cell，以保证 debug 的时候逻辑没有问题
    public func emptyCell() -> UICollectionViewCell { return _fatailError("cell 数据有问题，不应该调用这里的", value: UICollectionViewCell.init()) }
}


