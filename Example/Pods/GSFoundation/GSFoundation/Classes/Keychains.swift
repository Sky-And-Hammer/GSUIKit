//
//  Keychains.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation
import GSStability
import KeychainAccess

extension Constant {
    
    public static let KeyChainsServerName = Constant(rawValue: "com.Sky-And-Hammer.ios")
}

/// 需要存储内容的协议
public protocol KeychainsType {

    /// 存储 keychain 的key
    func keyIdentifier() -> String
}

public struct Keychains {

    fileprivate static var keychain = Keychain(service: Constant.KeyChainsServerName.rawValue)

    /// 初始化，其中只会初始化设备唯一 ID
    /// 初次安装 会在 UserDefaults.standard 写入 key，来保证 多次安装时不会使用脏数据
    public static func initialization() {
        if get(key: Normal.deviceID)?.isEmpty ?? true {
            set(key: Normal.deviceID, value: UIDevice.current.identifierForVendor?.uuidString ?? "0IOS0UDID0NOT0FOUND")
        }

        if !UserDefaults.standard.bool(forKey: Constant.KeyChainsServerName.rawValue) {
            destory()
            UserDefaults.standard.set(true, forKey: Constant.KeyChainsServerName.rawValue)
        }
    }

    /// 删除除去设备唯一 ID 的其他内容
    public static func destory() {
        keychain.allKeys().forEach {
            if $0 != Normal.deviceID.keyIdentifier() {
                try? keychain.remove($0)
            }
        }
    }

    /// 设备唯一 ID 到 keychain
    public static func deviceID() -> String {
        guard let value = get(key: Normal.deviceID) else {
            return "0IOS0UDID0NOT0FOUND"
        }

        return value
    }

    enum Normal: KeychainsType {
        case deviceID

        func keyIdentifier() -> String {
            return "Normal.deviceID"
        }
    }
}

public extension Keychains {

    /// 获取指定 key 的 value
    ///
    /// - Parameter key: 指定 key
    /// - Returns: 对应 value， nil 的时候为不存在
    static func get(key: KeychainsType) -> String? {
        return keychain[key.keyIdentifier()]
    }

//    /// 获取指定 key 的 model
//    ///
//    /// - Parameters:
//    ///   - key: 指定 key
//    ///   - type: 类型
//    /// - Returns: 对应 value， nil 的时候为不存在
//    static func get<T: HandyJSON>(key: KeychainsType, type: T.Type) -> T? {
//        guard let value = JSONDeserializer<T>.deserializeFrom(json: Keychains.get(key: key)) else {
//            return nil
//        }
//
//        return value
//    }

    /// 存储 key-value
    ///
    /// - Parameters:
    ///   - key: 指定 key
    ///   - value: 指定 value， nil 为删除
    static func set(key: KeychainsType, value: String?) {
        keychain[key.keyIdentifier()] = value
    }

    /// 存储 key-value
    ///
    /// - Parameters:
    ///   - key: 指定 key
    ///   - value: 指定 value， nil 为删除
    static func set(key: KeychainsType, model: GSJSON?) {
        set(key: key, value: model?.toJSONString())
    }
}

