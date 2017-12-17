//
//  PixelLineView.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

public var PixelWidth: CGFloat {
    return 1 / UIScreen.main.scale
}

public class PixelLineView: UIView {
    
    public enum PixelLinePosition: NSInteger {
        case horizontal, vertical
    }
    
    /// 线条颜色
    @IBInspectable public var lineColor: UIColor = UIColor.lightGray {
        didSet {
            backgroundColor = lineColor
        }
    }
    
    @IBInspectable public var position: NSInteger = 0 {
        didSet {
            self.location = PixelLinePosition(rawValue: position) ?? .horizontal
        }
    }
    
    var location: PixelLinePosition = .horizontal
    
    public override func updateConstraints() {
        backgroundColor = lineColor;
        
        snp.makeConstraints {
            switch location {
            case .horizontal:
                self.constraints.forEach({ (constraint) in
                    if constraint.firstAttribute == NSLayoutAttribute.height {
                        constraint.isActive = false
                    }
                })
                
                $0.height.equalTo(PixelWidth)
            case .vertical:
                self.constraints.forEach({ (constraint) in
                    if constraint.firstAttribute == NSLayoutAttribute.width {
                        constraint.isActive = false
                    }
                })
                
                $0.width.equalTo(PixelWidth)
            }
        }
        
        super.updateConstraints()
    }
    
    /// <#Description#>
    ///
    /// - Parameters:
    ///   - view: <#view description#>
    ///   - position: <#position description#>
    @discardableResult
    public static func addLine(in view: UIView, color: UIColor = UIColor.lightGray, position: PixelLinePosition) -> UIView {
        let view = UIView().then {
            $0.backgroundColor = color
            view.addSubview($0)
            
            $0.snp.makeConstraints({ (maker) in
                switch position {
                case .horizontal:
                    maker.top.leading.trailing.equalToSuperview()
                    maker.height.lessThanOrEqualTo(PixelWidth)
                case .vertical:
                    maker.top.bottom.trailing.equalToSuperview()
                    maker.width.lessThanOrEqualTo(PixelWidth)
                }
            })
        }
        
        return view
    }
}

