//
//  ImageCache.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability
import Kingfisher
import GSFoundation

// MARK: - ImageCache

// MARK: - Compatible for ImageCache

extension ImageCache: Compatible {}
extension KingfisherManager: Compatible {}

// MARK: - String

extension GS where Base == String {
    
    /// 通过 URL 直接查找图片
    ///
    /// - Parameters:
    ///   - targetCache: 指定的 imageCahce
    ///   - completed: closure, 未找到则返回 nil
    public func getImage(targetCache: ImageCache = ImageCache.default, completed: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: base) else { return completed(nil) }
        
        let cacheKey = ImageResource(downloadURL: url).cacheKey
        targetCache.retrieveImage(forKey: cacheKey, options: nil) { image,_ in completed(image) }
    }
}

// MARK: - ImageCache

extension GS where Base: ImageCache {
    
    /// cache 缓存图片到本地
    ///
    /// - Parameters:
    ///   - imageURL: 图片 URL
    ///   - options: KingfisherOptionsInfo
    ///   - progressBlock: 进度 closusre
    ///   - completed: 完成 closure
    public func store(url: String, options: KingfisherOptionsInfo = [KingfisherOptionsInfoItem](), progressBlock: DownloadProgressBlock? = nil, completed: CompletionHandler? = nil) {
        if let url = URL(string: url) {
            KingfisherManager.shared.retrieveImage(with: ImageResource(downloadURL: url), options: options, progressBlock: progressBlock, completionHandler: completed)
        } else { completed?(nil, nil, CacheType.none, nil) }
    }
    
    /// cache 删除本地图片
    ///
    /// - Parameter imageURL: 图片 URL
    public func delete(url: String) {
        if let url = URL(string: url) {
            base.removeImage(forKey: ImageResource(downloadURL: url).cacheKey)
        }
    }
}

// MARK: - KingfisherManager

extension GS where Base: KingfisherManager {
    
    /// 计算图片的本地缓存的总大小
    ///
    /// - Parameters:
    ///   - includedDefault: 是否包括 default cache
    ///   - completed: 完成 closure
    public func calculateDiskCacheSize(includedDefault: Bool = false, completed: @escaping(_ size: UInt) -> Void) {
        var cacheTotal: UInt = 0
        Async.background {
            Async.background {
                let group = AsyncGroup()
                (shareCache + (includedDefault ? [WeakWrapper(self.base.cache)] : [])).forEach {
                    group.enter()
                    $0.value?.calculateDiskCacheSize(completion: { (size) in
                        cacheTotal += size
                        group.leave()
                    })
                }
                
                group.wait(seconds: .seconds(10))
                group.main { completed(cacheTotal) }
            }
        }
    }
    
    /// 清除图片缓存
    ///
    /// - Parameter includedDefault: 是否包括 default cache
    public static func clean(includDefault: Bool) {
        NotificationCenter.default.post(name: Notification.Name.gs.ImageCache.cleanCcahe, object: nil, userInfo: nil)
    }
}

// MARK: - UIImageView

extension GS where Base: UIImageView {
    
    public func setImage(url: String?, targetCache: ImageCache = ImageCache.default, progressBlock: DownloadProgressBlock? = nil, completed: CompletionHandler? = nil) {
        let placeClosure: () -> Void = {
            self.base.placeholderView.isHidden = false
            progressBlock?(0, 0)
            completed?(nil, nil, .none, nil)
        }
        
        guard let url = url, !url.isEmpty else {
            return placeClosure()
        }
        
        if let remote = URL(string: url) {
            base.placeholderView.isHidden = false
            base.kf.setImage(with: ImageResource(downloadURL: remote), placeholder: nil, options: [.targetCache(targetCache)], progressBlock: progressBlock, completionHandler: {
                if $0 != nil {
                    self.base.placeholderView.isHidden = true
                }
                
                completed?($0, $1, $2, $3)
            })
        } else {
            if let image = UIImage(named: url) {
                if let completed = completed {
                    progressBlock?(0, 0)
                    completed(image, nil, .disk, nil)
                } else {
                    base.image = image
                    base.placeholderView.isHidden = true
                }
            } else {
                placeClosure()
            }
        }
    }
}

var shareCache: [WeakWrapper<ImageCache>] = []

// MARK: - Notification.Name

public extension Notification.Name.gs {
    
    public struct ImageCache {
        
        static let cleanCcahe = Notification.Name(notificationPrefix + ".ImageCache" + ".cleanCcahe")
    }
}

/// 业务块需要缓存图片则创建该对象， 然后调用下载缓存等方法时指定cache
public protocol GSImageCacheDelegate: NSObjectProtocol {
    
    func beforeCleanDiskCache(cache: GSImageCache)
}

public class GSImageCache: ImageCache {
    
    weak var delegate: GSImageCacheDelegate?
    
    public init(name: String, path: String? = nil, diskCachePathClosure: (String?, String) -> String = ImageCache.defaultDiskCachePathClosure, delegate: GSImageCacheDelegate) {
        self.delegate = delegate
        super.init(name: name, path: path, diskCachePathClosure: diskCachePathClosure)
        shareCache.append(WeakWrapper(self))
        
        NotificationCenter.default.gs.addObserver(self, name: Notification.Name.gs.ImageCache.cleanCcahe, object: nil) { (_, _) in
            self.delegate?.beforeCleanDiskCache(cache: self)
            self.clearDiskCache()
        }
    }
}

