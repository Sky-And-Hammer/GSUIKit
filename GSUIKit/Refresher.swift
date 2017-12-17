//
//  Refresher.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability
import GSFoundation

extension Images {
    
    public struct Refresh {
        
        /// RefreshHeaderAnimator 的icon 图片
        public static var pullIconImage = ""
        public static var pullIconBackgroundImage = ""
    }
}

// MARK: Extensions


private var kSJBRefreshHeader = "\(#file)+\(#line)"
private var kSJBRefreshFooter = "\(#file)+\(#line)"
public extension UIScrollView {
    
    public var header: RefreshHeader? {
        get { return objc_getAssociatedObject(self, &kSJBRefreshHeader) as? RefreshHeader }
        set { objc_setAssociatedObject(self, &kSJBRefreshHeader, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
    
    public var footer: RefreshFooter? {
        get { return objc_getAssociatedObject(self, &kSJBRefreshFooter) as? RefreshFooter }
        set { objc_setAssociatedObject(self, &kSJBRefreshFooter, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
    }
}

extension GS where Base: UIScrollView {
    
    @discardableResult
    public func addPull(animator: Refreshable & RefreshAnimatable = RefreshHeaderAnimator.init(), handler: @escaping RefreshHandler) -> RefreshHeader {
        removeHeader()
        return RefreshHeader(handler: handler, animator: animator).then {
            let height = $0.animator.executeIncremental
            base.header = $0
            base._add($0) {
                $0.height.equalTo(height)
                $0.width.equalTo(self.base.snp.width)
                $0.centerX.equalTo(self.base.snp.centerX)
                $0.bottom.equalTo(self.base.snp.top)
            }
        }
    }
    
    @discardableResult
    public func addInfinite(animator: Refreshable & RefreshAnimatable = RefreshFooterAnimator.init(), handler: @escaping RefreshHandler) -> RefreshFooter {
        removeFooter()
        return RefreshFooter(handler: handler, animator: animator).then {
            let height = $0.animator.executeIncremental
            base.footer = $0
            base._add($0) {
                $0.height.equalTo(height)
                $0.width.equalTo(self.base.snp.width)
                $0.centerX.equalTo(self.base.snp.centerX)
                $0.bottom.equalTo(self.base.snp.top)
                
            }
        }
    }
    
    public func removeHeader() {
        base.header?.stopRefreshing()
        base.header?.removeFromSuperview()
        base.header = nil
    }
    
    public func removeFooter() {
        base.footer?.stopRefreshing()
        base.footer?.removeFromSuperview()
        base.footer = nil
    }
    
    public func startPull() {
        Async.main { [weak base] in
            guard let base = base else { return }
            base.header?.startRefreshing(isAuto: false)
        }
    }
    
    public func autoPull() {
        
    }
    
    public func stopPull(ignoreData: Bool = false, ignoreFooter: Bool = false) {
        base.header?.stopRefreshing()
        if !ignoreData {
            resetNoMoreData()
        }
        
        base.footer?.isHidden = ignoreFooter
    }
    
    public func noticeNoMoreData() {
        base.footer?.noticeNoMoreData()
    }
    
    public func resetNoMoreData() {
        base.footer?.resetNoMoreData()
    }
    
    public func stopInfinite() {
        base.footer?.stopRefreshing()
    }
}


// MARK: - Refresh Animator

open class RefreshHeaderAnimator: UIView, Refreshable, RefreshAnimatable {
    
    open var loadinMoreDescription = "下拉刷新"
    open var loadingDescription = "正在刷新"
    open var releaseToRefreshDescription = "释放刷新"
    
    open var view: UIView { return self }
    open var duration: TimeInterval = 0.3
    open var delay: TimeInterval = 0
    open var insets: UIEdgeInsets = UIEdgeInsets.zero
    open var trigger: CGFloat = 1
    open var executeIncremental: CGFloat = 60
    open var state: RefreshViewState = .pullToRefresh
    
    var titleLabel = UILabel()
    var iconBGImage = UIImageView(image: UIImage(named: Images.Refresh.pullIconBackgroundImage))
    var iconImage = UIImageView(image: UIImage(named: Images.Refresh.pullIconImage))
    var indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    public required init() {
        super.init(frame: CGRect.zero)
        alpha = 0
        UIView().do { (view) in
            self._add(view) {
                $0.center.equalToSuperview()
            }
            
            view._add(iconBGImage) {
                $0.width.equalTo(27)
                $0.height.equalTo(22)
                $0.top.leading.bottom.equalToSuperview()
            }
            
            view._add(iconImage.then({
                $0.contentMode = .bottom
                $0.clipsToBounds = true
            })) {
                $0.width.equalTo(27)
                $0.height.equalTo(0)
                $0.centerX.equalTo(self.iconBGImage)
                $0.bottom.equalToSuperview()
            }
            
            view._add(indicatorView.then({
                $0.hidesWhenStopped = true
            })) {
                $0.center.equalTo(self.iconBGImage)
            }
            
            view._add(titleLabel.then({
                $0.font = UIFont.systemFont(ofSize: 14)
                $0.textColor = UIColor.init(hexString: "aaaaaa")
                $0.text = loadinMoreDescription
            })) {
                $0.centerY.equalToSuperview()
                $0.leading.equalTo(self.iconBGImage.snp.trailing).offset(10)
                $0.trailing.equalToSuperview()
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refreshAnimationBegin(view: RefreshComponent) {
        titleLabel.text = loadingDescription
    }
    
    public func refreshAnimationEnd(view: RefreshComponent) {
        indicatorView.stopAnimating()
        UIView.animate(withDuration: self.duration) {
            self.alpha = 0
        }
    }
    
    public func refresh(view: RefreshComponent, progressDidChanged progress: CGFloat, beginRefresh: Bool) {
        if self.state == .pullToRefresh {
            alpha = max(progress, 0.5)
        } else {
            alpha = 1
        }
        
        iconImage.snp.removeConstraints()
        iconImage.snp.makeConstraints {
            $0.width.equalTo(27)
            $0.centerX.equalTo(iconBGImage)
            $0.bottom.equalToSuperview()
            $0.height.equalTo(iconBGImage).multipliedBy(progress)
        }
        
        if progress >= trigger {
            // 超过 trigger， 如果是 beginRefresh 则 refreshing， 否则 releaseToRefresh
            refresh(view: view, stateDidChanged: beginRefresh ? .refreshing : .releaseToRefresh)
        } else {
            // 继续下啦刷新
            refresh(view: view, stateDidChanged: .pullToRefresh)
        }
    }
    
    public func refresh(view: RefreshComponent, stateDidChanged state: RefreshViewState) {
        guard self.state != state else { return }
        
        self.state = state
        switch self.state {
        case .refreshing, .autoRefreshing:
            indicatorView.startAnimating()
            titleLabel.text = loadingDescription
            iconImage.isHidden = true
            iconBGImage.isHidden = true
        case .pullToRefresh:
            iconImage.isHidden = false
            iconBGImage.isHidden = false
            titleLabel.text = loadinMoreDescription
        case .releaseToRefresh:
            iconImage.isHidden = false
            iconBGImage.isHidden = false
            titleLabel.text = releaseToRefreshDescription
        case .noMoreData:
            // ignore
            break
        }
    }
    
}


open class RefreshFooterAnimator: UIView, Refreshable, RefreshAnimatable {
    
    open var loadinMoreDescription = "上拉加载"
    open var noMoreDataDescription = "无更多内容"
    open var loadingDescription = "正在加载"
    open var releaseToRefreshDescription = "释放加载"
    
    open var view: UIView { return self }
    open var duration: TimeInterval = 0.3
    open var delay: TimeInterval = 0
    open var insets: UIEdgeInsets = UIEdgeInsets.zero
    open var trigger: CGFloat = 0.75
    open var executeIncremental: CGFloat = 42
    open var state: RefreshViewState = .pullToRefresh
    
    var titleLabel = UILabel()
    
    var loadingView = UIView()
    var indicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    
    public required init() {
        super.init(frame: CGRect.zero)
        alpha = 0
        
        self.do {
            $0._add(titleLabel.then({
                $0.font = UIFont.systemFont(ofSize: 14)
                $0.textColor = UIColor.init(hexString: "aaaaaa")
                $0.text = loadinMoreDescription
                $0.textAlignment = .center
            })) {
                $0.center.equalToSuperview()
                $0.width.equalTo(100)
                $0.height.equalToSuperview()
            }
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func refreshAnimationBegin(view: RefreshComponent) {
        titleLabel.text = loadingDescription
        indicatorView.startAnimating()
    }
    
    public func refreshAnimationEnd(view: RefreshComponent) {
        indicatorView.stopAnimating()
        UIView.animate(withDuration: self.duration) {
            self.alpha = 0
        }
    }
    
    public func refresh(view: RefreshComponent, progressDidChanged progress: CGFloat, beginRefresh: Bool) {
        let progress = max(min(1, progress), 0)
        
        if self.state == .pullToRefresh {
            alpha = max(progress, 0.5)
        } else {
            alpha = 1
        }
        
        if progress >= trigger {
            // 超过 trigger， 如果是 beginRefresh 则 refreshing， 否则 releaseToRefresh
            refresh(view: view, stateDidChanged: beginRefresh ? .refreshing : .releaseToRefresh)
        } else {
            // 继续下啦刷新
            refresh(view: view, stateDidChanged: .pullToRefresh)
        }
    }
    
    public func refresh(view: RefreshComponent, stateDidChanged state: RefreshViewState) {
        guard self.state != state else { return }
        
        self.state = state
        switch self.state {
        case .refreshing, .autoRefreshing:
            titleLabel.text = loadingDescription
        case .noMoreData:
            titleLabel.text = noMoreDataDescription
        case .pullToRefresh:
            titleLabel.text = loadinMoreDescription
        case .releaseToRefresh:
            titleLabel.text = releaseToRefreshDescription
        }
    }
}

// MARK: - Refresh Components

public typealias RefreshHandler = (() -> Void)

public class RefreshComponent: UIView {
    
    public weak var scrollView: UIScrollView?
    public private(set) var handler: RefreshHandler
    public private(set) var animator: (Refreshable & RefreshAnimatable)
    
    public private(set) var isRefreshing = false
    public private(set) var isAutoRefreshing = false
    
    public var progress: CGFloat { return 0 }
    
    var isObservingScrollView = false
    var isIgnoreObserving = false
    
    var pan: UIPanGestureRecognizer?
    
    public required init(handler: @escaping RefreshHandler, animator: (Refreshable & RefreshAnimatable)) {
        self.handler = handler
        self.animator = animator
        super.init(frame: CGRect.zero)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObserver()
    }
    
    public override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        removeObserver()
        Async.main { [weak self, newSuperview] in
            guard let `self` = self else { return }
            self.addObserver(newSuperview)
        }
    }
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        scrollView = superview as? UIScrollView
        if animator.view.superview == nil {
            let inset = animator.insets
            addSubview(animator.view)
            animator.view.frame = CGRect(x: inset.left,
                                         y: inset.right,
                                         width: bounds.size.width - inset.left - inset.right,
                                         height: bounds.size.height - inset.top - inset.bottom)
            animator.view.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleBottomMargin]
        }
    }
    
    // MARK: - KVO Methods
    
    private static var context = "RefreshComponentKVOContext"
    private static let offsetKeyPath = "contentOffset"
    private static let contentSizeKeyPath = "contentSize"
    private static let panStateKeyPath = "state"
    
    func ignoreObserver(_ ignore: Bool = false) {
        if let scrollView = scrollView {
            scrollView.isScrollEnabled = !ignore
        }
        
        isIgnoreObserving = ignore
    }
    
    func addObserver(_ view: UIView?) {
        if let scrollView = view as? UIScrollView, !isObservingScrollView {
            scrollView.addObserver(self, forKeyPath: RefreshComponent.offsetKeyPath, options: [.initial, .new], context: &RefreshComponent.context)
            scrollView.addObserver(self, forKeyPath: RefreshComponent.contentSizeKeyPath, options: [.initial, .new], context: &RefreshComponent.context)
            self.pan = scrollView.panGestureRecognizer
            self.pan?.addObserver(self, forKeyPath: RefreshComponent.panStateKeyPath, options: [.initial, .new], context: &RefreshComponent.context)
            isObservingScrollView = true
        }
    }
    
    func removeObserver() {
        if let scrollView = superview as? UIScrollView, isObservingScrollView {
            scrollView.removeObserver(self, forKeyPath: RefreshComponent.offsetKeyPath, context: &RefreshComponent.context)
            scrollView.removeObserver(self, forKeyPath: RefreshComponent.contentSizeKeyPath, context: &RefreshComponent.context)
            self.pan?.removeObserver(self, forKeyPath: RefreshComponent.panStateKeyPath)
            self.pan = nil
            isObservingScrollView = false
        }
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &RefreshComponent.context {
            guard isUserInteractionEnabled && !isIgnoreObserving else { return }
            
            if keyPath == RefreshComponent.contentSizeKeyPath {
                sizeChangeAction(object: object as AnyObject?, change: change)
            } else if keyPath == RefreshComponent.offsetKeyPath && !isHidden {
                offsetChangeAction(object: object as AnyObject?, change: change)
            } else if keyPath == RefreshComponent.panStateKeyPath && !isHidden {
                panStateChangeAction(object: object as AnyObject?, change: change)
            }
        }
    }
    
    
    // MARK: - Actions
    
    /// 进入刷新状态
    final func startRefreshing(isAuto: Bool = false) -> Void {
        guard !isRefreshing && !isAutoRefreshing else { return }
        
        isRefreshing = !isAuto
        isAutoRefreshing = isAuto
        start()
    }
    
    /// 停止刷新状态
    final func stopRefreshing() -> Void {
        guard isRefreshing || isAutoRefreshing else { return }
        stop()
    }
    
    /// 开始刷新, need override
    func start() {}
    
    /// 停止刷新, need override
    func stop() {
        isRefreshing = false
        isAutoRefreshing = false
    }
    
    /// ScrollView contentSize change action, need override
    func sizeChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey: Any]?) {}
    
    /// ScrollView offset change action, need override
    func offsetChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey: Any]?) {}
    
    /// pan state change action, need override
    func panStateChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey: Any]?) {}
}

public final class RefreshHeader: RefreshComponent {
    
    public override var progress: CGFloat {
        guard let scrollView = scrollView else { return super.progress }
        return max(min((-(scrollView.contentOffset.y + scrollViewInsets.top)) / animator.executeIncremental, 1), 0)
    }
    
    var scrollViewInsets: UIEdgeInsets = UIEdgeInsets.zero
    var scrollViewBounces = true
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        Async.main { [weak self] in
            guard let `self` = self else { return }
            self.scrollViewBounces = self.scrollView?.bounces ?? true
            self.scrollViewInsets = self.scrollView?.contentInset ?? UIEdgeInsets.zero
        }
    }
    
    override func offsetChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let _ = scrollView else { return }
        
        super.offsetChangeAction(object: object, change: change)
        guard !isRefreshing && !isAutoRefreshing else { return }
        
        animator.refresh(view: self, progressDidChanged: progress, beginRefresh: false)
    }
    
    override func panStateChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = scrollView else { return }
        super.panStateChangeAction(object: object, change: change)
        if scrollView.panGestureRecognizer.state == .ended {
            if progress >= animator.trigger {
                startRefreshing()
                animator.refresh(view: self, progressDidChanged: progress, beginRefresh: true)
            }
        }
    }
    
    override func start() {
        guard let scrollView = scrollView else { return }
        
        ignoreObserver(true)
        scrollView.bounces = false
        super.start()
        
        var insets = scrollView.contentInset
        scrollViewInsets.top = insets.top
        insets.top += animator.executeIncremental
        UIView.animate(withDuration: animator.duration, delay: animator.delay, options: .curveLinear, animations: {
            scrollView.contentInset = insets
            scrollView.contentOffset.y = -insets.top
        }) { (_) in
            self.handler()
            self.ignoreObserver(false)
            self.animator.refreshAnimationBegin(view: self)
            scrollView.bounces = self.scrollViewBounces
        }
    }
    
    override func stop() {
        guard let scrollView = scrollView else { return }
        
        ignoreObserver(true)
        UIView.animate(withDuration: animator.duration, delay: animator.delay, options: .curveLinear, animations: {
            scrollView.contentOffset.y = -self.scrollViewInsets.top
            scrollView.contentInset.top = self.scrollViewInsets.top
            self.animator.refresh(view: self, stateDidChanged: .pullToRefresh)
        }) { (finish) in
            super.stop()
            self.animator.refreshAnimationEnd(view: self)
            self.ignoreObserver(false)
        }
    }
}

public final class RefreshFooter: RefreshComponent {
    
    public private(set) var noMoreData = false
    
    public override var isHidden: Bool {
        didSet {
            if isHidden {
                scrollView?.contentInset.bottom = scrollViewInsets.bottom
                var rect = frame
                rect.origin.y = scrollView?.contentSize.height ?? 0
                frame = rect
            } else {
                scrollView?.contentInset.bottom = scrollViewInsets.bottom + animator.executeIncremental
                var rect = frame
                rect.origin.y = scrollView?.contentSize.height ?? 0
                frame = rect
            }
        }
    }
    
    public override var progress: CGFloat {
        guard let scrollView = scrollView else { return super.progress }
        
        if scrollView.contentInset.top + scrollView.contentSize.height > scrollView.frame.size.height {
            let value = (scrollView.contentOffset.y - (scrollView.contentSize.height - scrollView.frame.size.height + scrollView.contentInset.bottom)) / animator.executeIncremental
            return max(min(value, 1), 0)
        } else {
            let value = (scrollView.contentOffset.y + scrollView.contentInset.top) / animator.executeIncremental
            return max(min(value, 1), 0)
        }
    }
    
    var scrollViewInsets = UIEdgeInsets.zero
    
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        Async.main { [weak self] in
            guard let `self` = self else { return }
            self.scrollViewInsets = self.scrollView?.contentInset ?? UIEdgeInsets.zero
            self.scrollView?.contentInset.bottom = self.scrollViewInsets.bottom
            var rect = self.frame
            rect.origin.y = self.scrollView?.contentSize.height ?? 0
            self.frame = rect
        }
    }
    
    override func sizeChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = scrollView else { return }
        
        super.sizeChangeAction(object: object, change: change)
        let targetY = scrollView.contentSize.height + animator.executeIncremental
        snp.updateConstraints {
            // self.superView is scrollView
            $0.bottom.equalTo(scrollView.snp.top).offset(targetY)
        }
    }
    
    override func offsetChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = scrollView else { return }
        
        super.offsetChangeAction(object: object, change: change)
        guard !isRefreshing && !isAutoRefreshing && !isHidden else { return }
        
        if scrollView.contentSize.height <= 0 || scrollView.contentOffset.y + scrollView.contentInset.top <= 0 {
            // 展示内容为空 || 向上滑动
            return
        }
        
        animator.refresh(view: self, progressDidChanged: progress, beginRefresh: false)
    }
    
    override func panStateChangeAction(object: AnyObject?, change: [NSKeyValueChangeKey : Any]?) {
        guard let scrollView = scrollView else { return }
        
        super.panStateChangeAction(object: object, change: change)
        guard !isRefreshing && !isAutoRefreshing && !isHidden else {
            // 正在 refreshing，或者 isHidden
            return
        }
        
        if scrollView.contentSize.height <= 0 || scrollView.contentOffset.y + scrollView.contentInset.top <= 0 {
            // 展示内容为空 || 向上滑动
            return
        }
        
        if scrollView.panGestureRecognizer.state == .ended {
            if progress >= animator.trigger {
                startRefreshing()
                animator.refresh(view: self, progressDidChanged: progress, beginRefresh: true)
            }
        }
    }
    
    override func start() {
        guard let scrollView = scrollView else { return }
        
        super.start()
        
        UIView.animate(withDuration: animator.duration, delay: animator.delay, options: .curveLinear, animations: {
            scrollView.contentInset.bottom = self.animator.executeIncremental + self.scrollViewInsets.bottom
            let x = scrollView.contentOffset.x
            let y = max(0, scrollView.contentSize.height - scrollView.bounds.size.height + scrollView.contentInset.bottom)
            scrollView.contentOffset = CGPoint(x: x, y: y)
        }) { (_) in
            self.handler()
            
            self.animator.refreshAnimationBegin(view: self)
        }
    }
    
    override func stop() {
        guard let scrollView = scrollView else { return }
        
        UIView.animate(withDuration: animator.duration, delay: animator.delay, options: .curveLinear, animations: {
            if self.noMoreData {
                self.animator.refresh(view: self, stateDidChanged: .noMoreData)
            }
            
            scrollView.contentInset.bottom -= self.animator.executeIncremental
        }) { (_) in
            super.stop()
            self.animator.refreshAnimationEnd(view: self)
        }
        
        if scrollView.isDecelerating {
            var offset = scrollView.contentOffset
            offset.y = min(offset.y, scrollView.contentSize.height - scrollView.frame.size.height)
            if offset.y < 0 {
                offset.y = 0
                //TODO: 待确定
                UIView.animate(withDuration: 0.1, animations: {
                    scrollView.setContentOffset(offset, animated: false)
                })
            } else {
                scrollView.setContentOffset(offset, animated: false)
            }
        }
    }
    
    public func noticeNoMoreData() {
        noMoreData = true
    }
    
    public func resetNoMoreData() {
        noMoreData = false
    }
}

// MARK: - Protocols

public enum RefreshViewState {
    case pullToRefresh
    case releaseToRefresh
    case refreshing
    case autoRefreshing
    case noMoreData
}

public protocol Refreshable {
    
    func refreshAnimationBegin(view: RefreshComponent)
    func refreshAnimationEnd(view: RefreshComponent)
    
    func refresh(view: RefreshComponent, progressDidChanged progress: CGFloat, beginRefresh: Bool)
    func refresh(view: RefreshComponent, stateDidChanged state: RefreshViewState)
}

public protocol RefreshAnimatable {
    
    var view: UIView { get }
    var duration: TimeInterval { get }
    var delay: TimeInterval { get }
    var insets: UIEdgeInsets { get set }
    var trigger: CGFloat { get set }
    var executeIncremental: CGFloat { get set }
    var state: RefreshViewState { get set }
}

public protocol RefreshImpactable {}
public extension RefreshImpactable {
    
    public func impact() -> Void {
        RefreshImpacter.impact()
    }
    
}

fileprivate class RefreshImpacter {
    
    static private var impacter: AnyObject? = {
        if #available(iOS 10.0, *) {
            if NSClassFromString("UIFeedbackGenerator") != nil {
                return UIImpactFeedbackGenerator(style: .light).then {
                    $0.prepare()
                }
            }
        }
        
        return nil
    }()
    
    static open func impact() -> Void {
        if #available(iOS 10.0, *) {
            if let impacter = impacter as? UIImpactFeedbackGenerator {
                impacter.impactOccurred()
            }
        }
    }
}

