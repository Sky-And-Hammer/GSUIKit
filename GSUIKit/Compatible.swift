//
//  Compatible.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability
import GSFoundation
import Kingfisher

// MARK: - Compatible for UIKit

extension UIView: Compatible {}
extension UIViewController: Compatible {}

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
    /// 删除 view 的subview
    ///
    /// - Parameter closure: 是否删除的闭包判断
    public func removeSubviews(_ closure: ((UIView) -> Bool)? = nil) { base.subviews.forEach { if closure?($0) ?? true { $0.removeFromSuperview() } } }
    
    /// 设置 view 的圆角
    ///
    /// - Parameter radiuse: radiuse
    public func corner(`for` radius: CGFloat) { base.radius = radius }
    
    /// 设置 view 侧面半圆 或者直接变圆
    ///
    /// - Parameter isCircle:
    public func circle(isCircle: Bool) { base.isCircle = isCircle }
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


