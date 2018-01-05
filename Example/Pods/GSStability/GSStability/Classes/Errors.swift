//
//  Errors.swift
//  GSStabilitity
//
//  Created by 孟钰丰 on 2017/12/15.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

import Foundation

/// ErrorReason
public protocol GSErrorReason {
    
    /// 错误原因
    var reasonDescription: String { get }
}

/// Error.
/// For example:
///
///     enum APIError: GSError {
///
///         enum NetworkWrongReason {
///             case noNetwork
///             case timeout
///         }
///
///         enum ServerWrongReason {
///             case noResponse
///             case stateWrong(stateCode: Int)
///             case apiWrong(apiCode: Int)
///         }
///
///         case networkWrong(reason: NetworkWrongReason)
///         case serverWrong(reason: ServerWrongReason)
///     }
public protocol GSError: Error {}
