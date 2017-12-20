//
//  ViewProtocols.swift
//  GSUIKit
//
//  Created by 孟钰丰 on 2017/12/16.
//  Copyright © 2017年 孟钰丰. All rights reserved.
//

/// ViewAssmbling
public protocol ViewAssmbling: class {
    
    /// 配置页面显示的内容的属性 同时添加约束
    /// - 在 ‘draw(_ rect: CGRect)’ 最后手动调用
    func assembling(_ rect: CGRect)
}

//--------------------------------------------------------------------------
// MARK: - 独立处理展示数据逻辑的协议
//--------------------------------------------------------------------------

/// ViewIndieable
public protocol ViewIndieable: ViewAssmbling {
    
    associatedtype T
    
    /// 数据 model
    var model: T? { get set }
    
    /// 赋值 model，的同时并 修饰显示内容
    /// - 不要修改页面约束。除非你确定本身不回重复调用，比如 cell 的复用机制
    /// - 默认实现方式仅赋值
    ///
    /// - Parameter model: 数据
    func indieDecorate(model: T?)
}

public extension ViewIndieable {
    
    func indieDecorate(model: T?) { self.model = model }
}

public protocol CellIndieable: ViewIndieable {
    
    /// Cell 的 identifier
    /// - 默认实现为 type(of: self)
    static func Identifier() -> String
    
    /// 返回 cell 展示需要告诉
    /// - 默认实现为 CGSize.zero
    ///
    /// - Returns: 所需高度
    static func sizeForCell(model: T?) -> CGSize
}

public extension CellIndieable {
    
    static func Identifier() -> String { return "\(type(of: self))" }
    
    static func sizeForCell(model: T?) -> CGSize { return CGSize.zero }
}

//--------------------------------------------------------------------------
// MARK: - 用于 tableView & collectionView 用于规范 section 的业务逻辑
//--------------------------------------------------------------------------

public protocol Sectionabel: RawRepresentable {}

public extension Sectionabel {
    static func type(_ rowValue: Self.RawValue, `default` value:  Self) -> Self {
        return Self(rawValue: rowValue) ?? value
    }
}
