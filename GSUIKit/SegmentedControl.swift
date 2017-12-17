//
//  SegmentedControl.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability

/// SegmentedControl 的 option 配置属性
///
/// - titleColor: 未选中文字颜色
/// - titleFont: 未选中字体
/// - selectedTitleColor: 选中文字颜色
/// - selectedTitleFont: 选中字体
/// - titleBoardWidth: <#titleBoardWidth description#>
/// - titleBoardColor: <#titleBoardColor description#>
/// - titleNumberOfLines: <#titleNumberOfLines description#>
/// - indicatorViewBackgroundColor: <#indicatorViewBackgroundColor description#>
/// - indicatorViewInset: <#indicatorViewInset description#>
/// - indicatorViewBoarderWidth: <#indicatorViewBoarderWidth description#>
/// - indicatorViewBoarderColor: <#indicatorViewBoarderColor description#>
/// - alwaysAnnouncesValue: <#alwaysAnnouncesValue description#>
/// - announcesValueImmediately: <#announcesValueImmediately description#>
/// - panningDisabled: <#panningDisabled description#>
/// - backgroundColor: <#backgroundColor description#>
/// - cornerRadius: <#cornerRadius description#>
/// - bouncesOnChange: <#bouncesOnChange description#>
public enum SegmentedControlOptions {
    
    case titleColor(UIColor)
    case titleFont(UIFont)
    
    case selectedTitleColor(UIColor)
    case selectedTitleFont(UIFont)
    
    case titleBorderWidth(CGFloat)
    case titleBorderColor(UIColor)
    case titleNumberOfLines(Int)
    
    case indicatorViewBackgroundColor(UIColor)
    case indicatorViewInset(CGFloat)
    case indicatorViewBorderWidth(CGFloat)
    case indicatorViewBorderColor(UIColor)
    
    case alwaysAnnouncesValue(Bool)
    case announcesValueImmediately(Bool)
    case panningDisabled(Bool)
    
    case backgroundColor(UIColor)
    case cornerRadius(CGFloat)
    case bouncesOnChange(Bool)
}

public enum IndexError: GSError {
    case indexBeyondBounds(UInt)
}

// MARK: - SegmentedControl

open class SegmentedControl: UIControl {
    
    public fileprivate(set) var index: UInt
    public var titles: [String] {
        get { return titleLabels.map { $0.text ?? "" } }
        set {
            guard newValue.count > 1 else { return }
            let labels: [(UILabel, UILabel)] = newValue.map { title in
                return (UILabel.init().then {
                    $0.text = title
                    }, UILabel.init().then {
                        $0.text = title
                })
            }
            
            titleLabelsView.gs.removeSubviews()
            selectTitleLabelsView.gs.removeSubviews()
            labels.forEach {
                titleLabelsView.addSubview($0)
                selectTitleLabelsView.addSubview($1)
            }
            
            setNeedsLayout()
        }
    }
    
    public var options: [SegmentedControlOptions]? {
        get { return nil }
        set {
            guard let options = newValue else { return }
            options.forEach {
                switch $0 {
                case let .titleColor(value):
                    titleColor = value
                case let .titleFont(value):
                    titleFont = value
                case let .selectedTitleColor(value):
                    selectedTitleColor = value
                case let .selectedTitleFont(value):
                    selectedTitleFont = value
                case let .titleBorderWidth(value):
                    titleBorderWidth = value
                case let .titleBorderColor(value):
                    titleBorderColor = value
                case let .titleNumberOfLines(value):
                    titleNumberOfLines = value
                case let .indicatorViewBackgroundColor(value):
                    indicatorViewBackgroundColor = value
                case let .indicatorViewInset(value):
                    indicatorViewInset = value
                case let .indicatorViewBorderWidth(value):
                    indicatorViewBorderWidth = value
                case let .indicatorViewBorderColor(value):
                    indicatorViewBorderColor = value
                case let .alwaysAnnouncesValue(value):
                    alwaysAnnouncesValue = value
                case let .announcesValueImmediately(value):
                    announcesValueImmediately = value
                case let .panningDisabled(value):
                    panningDisabled = value
                case let .backgroundColor(value):
                    backgroundColor = value
                case let .cornerRadius(value):
                    cornerRadius = value
                case let .bouncesOnChange(value):
                    bouncesOnChange = value
                }
            }
        }
    }
    
    @IBInspectable public fileprivate(set) var bouncesOnChange = true
    @IBInspectable public fileprivate(set) var alwaysAnnouncesValue = false
    @IBInspectable public fileprivate(set) var announcesValueImmediately = true
    @IBInspectable public fileprivate(set) var panningDisabled = false
    
    
    @IBInspectable public fileprivate(set) var cornerRadius: CGFloat {
        get { return layer.cornerRadius }
        set {
            layer.cornerRadius = newValue
            indicatorView.cornerRadius = newValue - indicatorViewInset
            titleLabels.forEach { $0.layer.cornerRadius = indicatorView.cornerRadius }
        }
    }
    @IBInspectable public fileprivate(set) var indicatorViewBackgroundColor: UIColor? {
        get { return indicatorView.backgroundColor }
        set { indicatorView.backgroundColor = newValue }
    }
    @IBInspectable public fileprivate(set) var indicatorViewInset: CGFloat = 2 { didSet { setNeedsLayout() } }
    @IBInspectable public fileprivate(set) var indicatorViewBorderWidth: CGFloat {
        get { return indicatorView.layer.borderWidth }
        set { indicatorView.layer.borderWidth = newValue }
    }
    @IBInspectable public fileprivate(set) var indicatorViewBorderColor: UIColor? {
        get { guard let color = indicatorView.layer.borderColor else { return nil }; return UIColor.init(cgColor: color) }
        set { indicatorView.layer.borderColor = newValue?.cgColor }
    }
    @IBInspectable public fileprivate(set) var titleColor = Color.title { didSet { titleLabels.forEach { $0.textColor = titleColor } } }
    @IBInspectable public fileprivate(set) var selectedTitleColor = Color.selectedTitle { didSet { selectedTitleLabels.forEach { $0.textColor = selectedTitleColor } } }
    public var titleFont = UILabel.init().font { didSet { titleLabels.forEach { $0.font = titleFont} } }
    public var selectedTitleFont = UILabel.init().font { didSet { selectedTitleLabels.forEach { $0.font = selectedTitleFont } } }
    @IBInspectable public fileprivate(set) var titleBorderWidth: CGFloat = 0 { didSet { titleLabels.forEach { $0.layer.borderWidth = titleBorderWidth } } }
    @IBInspectable public fileprivate(set) var titleNumberOfLines = 0 {
        didSet {
            titleLabels.forEach { $0.numberOfLines = titleNumberOfLines }
            selectedTitleLabels.forEach { $0.numberOfLines = titleNumberOfLines }
        }
    }
    @IBInspectable public fileprivate(set) var titleBorderColor = UIColor.clear { didSet { titleLabels.forEach { $0.layer.borderColor = titleBorderColor.cgColor } } }
    
    fileprivate let titleLabelsView = UIView.init()
    fileprivate let selectTitleLabelsView = UIView.init()
    fileprivate let indicatorView = IndicatorView.init()
    fileprivate var initialIndicatorViewFrame: CGRect?
    
    fileprivate var tapGestureRecognizer: UITapGestureRecognizer!
    fileprivate var panGestureRecognizer: UIPanGestureRecognizer!
    
    fileprivate var width: CGFloat { return bounds.width }
    fileprivate var height: CGFloat { return bounds.height }
    fileprivate var titleLabelsCount: Int { return titleLabelsView.subviews.count }
    fileprivate var titleLabels: [UILabel] { return titleLabelsView.subviews as? [UILabel] ?? [] }
    fileprivate var selectedTitleLabels: [UILabel] { return selectTitleLabelsView.subviews as? [UILabel] ?? [] }
    fileprivate var totalInsetSize: CGFloat { return indicatorViewInset * 2 }
    
    public init(frame: CGRect, titles: [String], index: UInt = 0, options: [SegmentedControlOptions]? = nil) {
        self.index = index
        super.init(frame: frame)
        self.titles = titles
        self.options = options
        finishInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        self.index = 0
        super.init(coder: aDecoder)
        self.titles = []
        finishInit()
    }
    
    private func finishInit() {
        self.do {
            $0.layer.masksToBounds = true
            $0.addSubview(titleLabelsView)
            $0.addSubview(indicatorView)
            $0.addSubview(selectTitleLabelsView)
            selectTitleLabelsView.layer.mask = indicatorView.titleMaskView.layer
            
            tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped(_:)))
            addGestureRecognizer(tapGestureRecognizer)
            
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
            panGestureRecognizer.delegate = self
            addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        guard titleLabelsCount > 1 else { return }
        
        titleLabelsView.frame = bounds
        selectTitleLabelsView.frame = bounds
        indicatorView.frame = elementFrame(forIndex: index)
        for index in 0..<titleLabelsCount {
            let frame = elementFrame(forIndex: UInt(index))
            titleLabelsView.subviews[index].frame = frame
            selectTitleLabelsView.subviews[index].frame = frame
        }
    }
}

// MARK: - Public Methods

extension SegmentedControl {
    
    public func setIndex(_ index: UInt, animated: Bool = true) throws {
        guard titleLabels.indices.contains(Int(index)) else { throw IndexError.indexBeyondBounds(index) }
        
        let oldIndex = index
        self.index = index
        moveIndicator(animated: animated, shouldSendEvent: (self.index != oldIndex) || alwaysAnnouncesValue)
    }
    
    public func addSubview(toIndicator view: UIView) { indicatorView.addSubview(view) }
}


// MARK: - UIGestureRecognizerDelegate

extension SegmentedControl: UIGestureRecognizerDelegate {
    
    open override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer == panGestureRecognizer else { return super.gestureRecognizerShouldBegin(gestureRecognizer) }
        
        return indicatorView.frame.contains(gestureRecognizer.location(in: self))
    }
}

// MARK: - UIGestureRecognizer

extension SegmentedControl {
    
    @objc fileprivate func tapped(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        try? setIndex(nearestIndex(toPoint: location))
    }
    
    @objc fileprivate func panned(_ gestureRecognizer: UIPanGestureRecognizer!) {
        guard !panningDisabled else { return }
        
        switch gestureRecognizer.state {
        case .began:
            initialIndicatorViewFrame = indicatorView.frame
        case .changed:
            var frame = initialIndicatorViewFrame!
            frame.origin.x += gestureRecognizer.translation(in: self).x
            frame.origin.x = max(min(frame.origin.x, bounds.width - indicatorViewInset - frame.width), indicatorViewInset)
            indicatorView.frame = frame
        case .ended, .failed, .cancelled:
            try? setIndex(nearestIndex(toPoint: indicatorView.center))
        default: break
        }
    }
}

// MARK: - Private Methods

extension SegmentedControl {
    
    fileprivate func moveIndicator(animated: Bool, shouldSendEvent: Bool) {
        if animated {
            if shouldSendEvent && announcesValueImmediately { sendActions(for: .valueChanged) }
            UIView.animate(withDuration: bouncesOnChange ? Animation.withBounceDuration : Animation.withoutBounceDuration,
                           delay: 0,
                           usingSpringWithDamping: bouncesOnChange ? Animation.springDamping : 1,
                           initialSpringVelocity: 0,
                           options: [.beginFromCurrentState, .curveEaseOut],
                           animations: {
                            self.moveIndicatorView()
            }, completion: { (finished) in
                if finished && shouldSendEvent && !self.announcesValueImmediately { self.sendActions(for: .valueChanged) }
            })
        } else {
            moveIndicatorView()
            sendActions(for: .valueChanged)
        }
    }
    
    fileprivate func moveIndicatorView() {
        indicatorView.frame = titleLabels[Int(index)].frame
        layoutIfNeeded()
    }
    
    fileprivate func elementFrame(forIndex index: UInt) -> CGRect {
        let elementWidth = (width - totalInsetSize) / CGFloat(titleLabelsCount)
        return CGRect.init(x: CGFloat(index) * elementWidth + indicatorViewInset, y: indicatorViewInset, width: elementWidth, height: height - totalInsetSize)
    }
    
    fileprivate func nearestIndex(toPoint point: CGPoint) -> UInt {
        let distances = titleLabels.map { abs(point.x - $0.center.x) }
        return UInt(distances.index(of: distances.min()!)!)
    }
}

// MARK: - Inner views

extension SegmentedControl {
    
    // MARK: - IndicatorView
    
    fileprivate class IndicatorView: UIView {
        
        override var frame: CGRect { didSet { titleMaskView.frame = frame } }
        
        fileprivate let titleMaskView = UIView.init()
        fileprivate var cornerRadius: CGFloat = 0 {
            didSet {
                layer.cornerRadius = cornerRadius
                titleMaskView.layer.cornerRadius = cornerRadius
            }
        }
        
        init() { super.init(frame: CGRect.zero); finishInit() }
        
        required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); finishInit() }
        
        private func finishInit() {
            layer.masksToBounds = true
            titleMaskView.backgroundColor = UIColor.black
        }
    }
    
    // MARK: - Animation
    
    fileprivate struct Animation {
        fileprivate static let withBounceDuration: TimeInterval = 0.3
        fileprivate static let springDamping: CGFloat = 0.75
        fileprivate static let withoutBounceDuration: TimeInterval = 0.2
    }
    
    // MARK: - Color
    
    fileprivate struct Color {
        fileprivate static let backgound = UIColor.white
        fileprivate static let title = UIColor.black
        fileprivate static let indicatorViewBackground = UIColor.black
        fileprivate static let selectedTitle = UIColor.white
    }
}

