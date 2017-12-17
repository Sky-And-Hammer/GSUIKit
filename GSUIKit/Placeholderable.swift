//
//  Placeholderable.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

public extension Images {
    
    /// 默认加载图片
    public static var imagePlaceHolder = ""
}

public extension Colors {
    
    public static var imagePlaceHolderBgColor = UIColor.init(hexString: "FEEFE4")
}


protocol Placeholderable {
    
    var placeholderView: ImagePlaceholderView { get }
}

final class ImagePlaceholderView: UIView {
    
    lazy var imageView: UIImageView = {
        return UIImageView(image: UIImage(named: Images.imagePlaceHolder)).then {
            $0.contentMode = .scaleAspectFit
            self._add($0) {
                $0.center.equalToSuperview()
            }
        }
    }()
    
    init() {
        super.init(frame: CGRect.zero)
        imageView.isHidden = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private var kSJBPlaceholder = "\(#file)+\(#line)"
extension UIImageView: Placeholderable {
    
    fileprivate var _placehoderView: ImagePlaceholderView {
        get {
            guard let view = objc_getAssociatedObject(self, &kSJBPlaceholder) as? ImagePlaceholderView else {
                let view = ImagePlaceholderView().then {
                    $0.backgroundColor = Colors.imagePlaceHolderBgColor
                    insertSubview($0, at: 0)
                    self._placehoderView = $0
                    
                    $0.snp.makeConstraints {
                        $0.leading.top.trailing.bottom.equalToSuperview()
                    }
                }
                
                return view
            }
            
            return view
        }
        set { objc_setAssociatedObject(self, &kSJBPlaceholder, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    var placeholderView: ImagePlaceholderView { return _placehoderView }
}
