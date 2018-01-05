//
//  Notifications.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    /// notification 的前缀.
    /// For example:
    ///
    ///    public extension Notification.Name.gs {
    ///
    ///        public struct NetworkState {
    ///
    ///            public static let networkStateChange = Notification.Name(rawValue: notificationPrefix + ".NetworkState" + ".networkStateChange")
    ///            static let networkStateChangeInner = Notification.Name(rawValue: notificationPrefix + ".NetworkState" + ".networkStateChange.inner")
    ///        }
    ///    }
    public struct gs {
        
        public static let notificationPrefix = "com.Sky-And-Hammer.ios.GS"
    }
}
