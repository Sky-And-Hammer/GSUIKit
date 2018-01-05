//
//  JSONMappable.swift
//  GSFoundation
//
//  Created by 孟钰丰 on 2018/1/3.
//

import Foundation

// MARK: GSJSONCustomTransformable

public protocol GSJSONCustomTransformable: _ExtendCustomBasicType {}

// MARK: GSJSON

public protocol GSJSON: _ExtendCustomModelType {}

// MARK: GSJSON Serializer

extension GSJSON {
    
    public func toJSON() -> [String: Any]? { return Self._serializeAny(object: self) as? [String: Any] ?? nil }
    public func toJSONString(prettyPrint: Bool = false) -> String? {
        guard let anyObject = toJSON() else { return nil }
        if JSONSerialization.isValidJSONObject(anyObject) {
            do {
                return String.init(data: try JSONSerialization.data(withJSONObject: anyObject, options: (prettyPrint ? [.prettyPrinted] : [])), encoding: .utf8)
            } catch  {
            }
        }
        
        return nil
    }
}

public extension Collection where Iterator.Element: GSJSON {
    
    public func toJSON() -> [[String: Any]?] { return map { $0.toJSON() } }
    public func toJSONString(prettyPrint: Bool = false) -> String? {
        let anyArray = toJSON()
        if JSONSerialization.isValidJSONObject(anyArray) {
            do {
                return String.init(data: try JSONSerialization.data(withJSONObject: anyArray, options: (prettyPrint ? [.prettyPrinted] : [])), encoding: .utf8)
            } catch {
                
            }
        }
        
        return nil
    }
}

// MARK: GSJSON Deserializer

public extension GSJSON {
    
    public static func json(from dic: NSDictionary?, designatedPath: String? = nil) -> Self? {
        return json(from: dic as? [String: Any], designatedPath: designatedPath)
    }
    
    public static func json(from dict: [String: Any]?, designatedPath: String? = nil) -> Self? {
        return JSONDeserializer<Self>.jsonFrom(dict: dict, designatedPath: designatedPath)
    }
    
    public static func json(from json: String?, designatedPath: String? = nil) -> Self? {
        return JSONDeserializer<Self>.jsonFrom(json: json, designatedPath: designatedPath)
    }
}

public extension Array where Element: GSJSON {
    
    public static func json(from json:String?, designatedPath: String? = nil) -> [Element?]? {
        return JSONDeserializer<Element>.json(from: json, designatedPath: designatedPath)
    }
    
    public static func json(from array: NSArray?) -> [Element?]? {
        return JSONDeserializer<Element>.json(from: array)
    }
    
    public static func json(from array: [Any]?) -> [Element?]? {
        return JSONDeserializer<Element>.json(from: array)
    }
}

class JSONDeserializer<T: GSJSON> {
    
    static func jsonFrom(dict: NSDictionary?, designatedPath: String? = nil) -> T? {
        return jsonFrom(dict: dict as? [String: Any], designatedPath: designatedPath)
    }
    
    static func jsonFrom(dict: [String: Any]?, designatedPath: String? = nil) -> T? {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        if let dict = targetDict {
            return T._transform(dict: dict) as? T
        }
        
        return nil
    }
    
    static func jsonFrom(json: String?, designatedPath: String? = nil) -> T? {
        guard let json = json else { return nil }
        if let jsonDict = json.unwrapper() as? NSDictionary {
            return jsonFrom(dict: jsonDict, designatedPath: designatedPath)
        } else { return nil }
    }
    
    static func json(from json: String?, designatedPath: String? = nil) -> [T?]? {
        guard let json = json else { return nil }
        if let jsonArray = getInnerObject(inside: json.unwrapper() as? [Any], by: designatedPath) as? [Any] {
            return jsonArray.map { jsonFrom(dict: $0 as? [String: Any]) }
        } else { return nil }
    }
    
    static func json(from array: NSArray?) -> [T?]? { return json(from: array as? [Any]) }
    
    static func json(from array: [Any]?) -> [T?]? {
        guard let arr = array else { return nil }
        return arr.map { jsonFrom(dict: $0 as? NSDictionary) }
    }
    
    static func update(object: inout T, from json: String?, designatedPath: String? = nil) {
        guard let json = json else { return }
        if let jsonDict = json.unwrapper() as? [String: Any] { update(object: &object, from: jsonDict, designatedPath: designatedPath) }
    }
    
    static func update(object: inout T, from dict: [String: Any]?, designatedPath: String? = nil) {
        var targetDict = dict
        if let path = designatedPath {
            targetDict = getInnerObject(inside: targetDict, by: path) as? [String: Any]
        }
        
        if let dict = targetDict {
            T._transform(dict: dict, to: &object)
        }
    }
}

extension String  {
    
    func unwrapper() -> Any? {
        return try? JSONSerialization.jsonObject(with: self.data(using: String.Encoding.utf8)!, options: .allowFragments)
    }
}

fileprivate func getInnerObject(inside object: Any?, by designatedPath: String?) -> Any? {
    var result: Any? = object
    var abort = false
    if let paths = designatedPath?.components(separatedBy: "."), paths.count > 0 {
        var next = object as? [String: Any]
        paths.forEach {
            if $0.trimmingCharacters(in: .whitespacesAndNewlines) == "" || abort { return }
            if let _next = next?[$0] {
                result = _next
                next = _next as? [String: Any]
            } else { abort = true }
        }
    }
    
    return abort ? nil : result
}

// MARK: GSJSONEnum

public protocol GSJSONEnum: _RawEnumProtocol {}

// MARK: Property

/// An instance property
struct Property {
    let key: String
    let value: Any
    
    /// An instance property description
    struct Description {
        public let key: String
        public let type: Any.Type
        public let offset: Int
        public func write(_ value: Any, to storage: UnsafeMutableRawPointer) { return extensions(of: type).write(value, to: storage.advanced(by: offset))}
    }
}

/// Retrieve properties for `instance`
func getProperties(forInstance instance: Any) -> [Property]? {
    if let props = getProperties(forType: type(of: instance)) {
        var copy = extensions(of: instance)
        let storage = copy.storage()
        return props.map { nextProperty(description: $0, storage: storage) }
    } else { return nil }
}

private func nextProperty(description: Property.Description, storage: UnsafeRawPointer) -> Property {
    return Property.init(key: description.key, value: extensions(of: description.type).value(from: storage.advanced(by: description.offset)))
}

/// Retrieve property descriptions for `type`
func getProperties(forType type: Any.Type) -> [Property.Description]? {
    if let nominalType = Metadata.Struct.init(anyType: type) { return fetchProperties(nominalType: nominalType) }
    else if let nominalType = Metadata.Class.init(anyType: type) { return nominalType.properties() }
    else if let nominalType = Metadata.ObjcClassWrapper.init(anyType: type), let targetType = nominalType.targetType { return getProperties(forType: targetType) }
    else { return nil }
}

func fetchProperties<T: NominalType>(nominalType: T) -> [Property.Description]? { return propertiesForNominalType(nominalType) }

private func propertiesForNominalType<T: NominalType>(_ type: T) -> [Property.Description]? {
    guard let descriptor = type.nominalTypeDescriptor else { return nil }
    guard descriptor.numberOfFields != 0 else { return [] }
    guard let fieldTypes = type.fieldTypes, let fieldOffsets = type.fieldOffsets else { return nil }
    let fieldNames = descriptor.fieldNames
    return (0..<descriptor.numberOfFields).map { Property.Description.init(key: fieldNames[$0], type: fieldTypes[$0], offset: fieldOffsets[$0]) }
}

// MARK: AnyExtensions

protocol AnyExtensions {}
extension AnyExtensions {
    
    public static func isValueTypeOrSubType(_ value: Any) -> Bool { return value is Self }
    
    public static func value(from storage: UnsafeRawPointer) -> Any { return storage.assumingMemoryBound(to: self).customPlaygroundQuickLook }
    
    public static func write(_ value: Any, to storage: UnsafeMutableRawPointer) {
        guard let thisValue = value as? Self else { return }
        storage.assumingMemoryBound(to: self).pointee = thisValue
    }
    
    public static func takeValue(from anyValue: Any) -> Self? { return anyValue as? Self }
}

func extensions(of type: Any.Type) -> AnyExtensions.Type {
    struct Extensions: AnyExtensions {}
    var extensions: AnyExtensions.Type = Extensions.self
    withUnsafePointer(to: &extensions) { UnsafeMutableRawPointer(mutating: $0).assumingMemoryBound(to: Any.Type.self).pointee = type }
    
    return extensions
}

func extensions(of value: Any) -> AnyExtensions {
    struct Extensions: AnyExtensions {}
    var extensions: AnyExtensions = Extensions.init()
    withUnsafePointer(to: &extensions) { UnsafeMutableRawPointer(mutating: $0).assumingMemoryBound(to: Any.self).pointee = value }
    
    return extensions
}

/// Tests if `value` is `type` or a subclass of `type`
func value(_ value: Any, is type: Any.Type) -> Bool { return extensions(of: type).isValueTypeOrSubType(value) }

/// Tests equality of any two existential types
func == (lhs: Any.Type, rhs: Any.Type) -> Bool {
    return Metadata(type: lhs) == Metadata(type: rhs)
}

// MARK: AnyExtension + Storage

extension AnyExtensions {
    
    mutating func storage() -> UnsafeRawPointer {
        if type(of: self) is AnyClass { return UnsafeRawPointer.init(Unmanaged.passUnretained(self as AnyObject).toOpaque()) }
        else { return withUnsafePointer(to: &self) { return UnsafeRawPointer.init($0) } }
    }
}

// MARK: PointerType

protocol PointerType: Equatable {
    
    associatedtype Pointee
    var pointer: UnsafePointer<Pointee> { get set }
}

extension PointerType {
    init<T>(pointer: UnsafePointer<T>) {
        func cast<T, U>(_ value: T) -> U { return unsafeBitCast(value, to: U.self) }
        self = cast(UnsafePointer<Pointee>(pointer))
    }
}

func == <T: PointerType>(lhs: T, rhs: T) -> Bool { return lhs.pointer == rhs.pointer }

// MARK: Metadata

struct _class_rw_t {
    var flags: Int32
    var version: Int32
    var ro: UInt
    // other fields we don't care
    
    func class_ro_t() -> UnsafePointer<_class_ro_t>? { return UnsafePointer<_class_ro_t>.init(bitPattern: self.ro) }
}

struct _class_ro_t {
    var flags: Int32
    var instanceStart: Int32
    var instanceSize: Int32
    // other fields we don't care
}

struct Metadata: MetadataType {
    
    var pointer: UnsafePointer<Int>
    
    init(type: Any.Type) { self.init(pointer: unsafeBitCast(type, to: UnsafePointer<Int>.self)) }
}

struct _Metadata {}

var is64BitPlatform: Bool { return MemoryLayout<Int>.size == MemoryLayout<Int64>.size }

// MARK: MetadataType

protocol MetadataType: PointerType {
    static var kind: Metadata.Kind? { get }
}

extension MetadataType {
    
    var kind: Metadata.Kind { return Metadata.Kind.init(flag: UnsafePointer<Int>(pointer).pointee) }
    
    init?(anyType: Any.Type) {
        self.init(pointer: unsafeBitCast(anyType, to: UnsafePointer<Int>.self))
        if let kind = type(of: self).kind, kind != self.kind { return nil }
    }
}

// MARK: Metadata + Kind
// https://github.com/apple/swift/blob/swift-3.0-branch/include/swift/ABI/MetadataKind.def
extension Metadata {
    static let kind: Kind? = nil
    
    enum Kind {
        case `struct`
        case `enum`
        case optional
        case opaque
        case tuple
        case function
        case existential
        case metatype
        case objCClassWrapper
        case existentialMetatype
        case foreignClass
        case heapLocalVariable
        case heapGenericLocalVariable
        case errorObject
        case `class`
        init(flag: Int) {
            switch flag {
            case 1: self = .struct
            case 2: self = .enum
            case 3: self = .optional
            case 8: self = .opaque
            case 9: self = .tuple
            case 10: self = .function
            case 12: self = .existential
            case 13: self = .metatype
            case 14: self = .objCClassWrapper
            case 15: self = .existentialMetatype
            case 16: self = .foreignClass
            case 64: self = .heapLocalVariable
            case 65: self = .heapGenericLocalVariable
            case 128: self = .errorObject
            default: self = .class
            }
        }
    }
}

// MARK: Metadata + Class

extension Metadata {
    
    struct Class: NominalType {
        static var kind: Kind? = .class
        var pointer: UnsafePointer<_Metadata._Class>
        var nominalTypeDescriptorOffsetLocation: Int { return is64BitPlatform ? 8 : 11 }
        var isSwiftClass: Bool { return (pointer.pointee.databits & 1) == 1 }
        var superClass: Class? {
            guard let superclass = pointer.pointee.superclass else { return nil }
            // If the superclass doesn't conform to handyjson/handyjsonenum protocol,
            // we should ignore the properties inside
            if !(superclass is GSJSON.Type) && !(superclass is GSJSONEnum.Type) { return nil }
            // ignore objc-runtime layer
            guard let metaclass = Metadata.Class(anyType: superclass), metaclass.isSwiftClass else { return nil }
            return metaclass
        }
        
        func properties() -> [Property.Description]? {
            let propsAndStp = _propertiesAndStartPoint()
            if let firstInstanceStart = propsAndStp?.1, let firstProperty = propsAndStp?.0.first {
                return propsAndStp?.0.map { Property.Description.init(key: $0.key, type: $0.type, offset: $0.offset - firstProperty.offset + Int(firstInstanceStart)) }
            } else { return propsAndStp?.0 }
        }
        
        private func _propertiesAndStartPoint() -> ([Property.Description], Int32?)? {
            let instanceStart = pointer.pointee.class_rw_t()?.pointee.class_ro_t()?.pointee.instanceStart
            var result: [Property.Description] = []
            if let properties = fetchProperties(nominalType: self) { result = properties }
            if let superclass = superClass,
                String(describing: unsafeBitCast(superclass.pointer, to: Any.Type.self)) != "SwiftObject",  // ignore the root swift object
                let superclassProperties = superClass?._propertiesAndStartPoint() {
                return (superclassProperties.0 + result, superclassProperties.1)
            }
            
            return (result, instanceStart)
        }
    }
}

extension _Metadata {
    struct _Class {
        var kind: Int
        var superclass: Any.Type?
        var reserveword1: Int
        var reserveword2: Int
        var databits: UInt
        // other fields we don't care
        
        func class_rw_t() -> UnsafePointer<_class_rw_t>? {
            if is64BitPlatform {
                let fast_data_mask: UInt64 = 0x00007ffffffffff8
                let databits_t = UInt64(self.databits)
                return UnsafePointer<_class_rw_t>(bitPattern: UInt(databits_t & fast_data_mask))
            } else { return UnsafePointer<_class_rw_t>(bitPattern: databits & 0xfffffffc) }
        }
    }
}

// MARK: Metadata + Struct

extension Metadata {
    struct Struct: NominalType {
        static var kind: Kind? = .struct
        var pointer: UnsafePointer<_Metadata._Struct>
        var nominalTypeDescriptorOffsetLocation: Int { return 1 }
    }
}

extension _Metadata {
    struct _Struct {
        var kind: Int
        var nominalTypeDescriptorOffset: Int
        var parent: Metadata?
    }
}

// MARK: Metadata + ObjcClassWrapper

extension Metadata {
    struct ObjcClassWrapper: NominalType {
        static let kind: Kind? = .objCClassWrapper
        var pointer: UnsafePointer<_Metadata._ObjcClassWrapper>
        var nominalTypeDescriptorOffsetLocation: Int { return is64BitPlatform ? 8 : 11 }
        var targetType: Any.Type? { return pointer.pointee.targetType }
    }
}

extension _Metadata {
    struct _ObjcClassWrapper {
        var kind: Int
        var targetType: Any.Type?
    }
}

// MARK: NominalType

protocol NominalType: MetadataType {
    
    var nominalTypeDescriptorOffsetLocation: Int { get }
}

extension NominalType {
    var nominalTypeDescriptor: NominalTypeDescriptor? {
        let base = UnsafePointer<Int>.init(pointer).advanced(by: nominalTypeDescriptorOffsetLocation)
        if base.pointee == 0 { return nil /** swift class created dynamically in objc-runtime didn't have valid nominalTypeDescriptor **/ }
        else { return NominalTypeDescriptor.init(pointer: relativePointer(base: base, offset: base.pointee)) }
    }
    
    var fieldTypes: [Any.Type]? {
        guard let descirptor = nominalTypeDescriptor else { return nil }
        guard let functions = descirptor.fieldTypesAccessor else { return nil }
        return (0..<descirptor.numberOfFields).map { unsafeBitCast(functions(UnsafePointer<Int>.init(pointer)).advanced(by: $0).pointee, to: Any.Type.self) }
    }
    
    var fieldOffsets: [Int]? {
        guard let descirptor = nominalTypeDescriptor else { return nil }
        let vectorOffset = descirptor.fieldOffsetVector
        guard vectorOffset != 0 else { return nil }
        return (0..<descirptor.numberOfFields).map { UnsafePointer<Int>(pointer)[vectorOffset + $0] }
    }
}

struct NominalTypeDescriptor: PointerType {
    
    var pointer: UnsafePointer<_NominalTypeDescriptor>
    
    var mangledName: String { return String.init(cString: relativePointer(base: pointer, offset: pointer.pointee.mangledName) as UnsafePointer<CChar>) }
    var numberOfFields: Int { return Int(pointer.pointee.numberOfFields) }
    var fieldOffsetVector: Int { return Int(pointer.pointee.fieldOffsetVector) }
    var fieldNames: [String] { return Array.init(utf8Strings: relativePointer(base: UnsafePointer<Int32>(pointer).advanced(by: 3), offset: pointer.pointee.fieldNames)) }
    
    typealias FieldsTypeAccessor = @convention(c) (UnsafePointer<Int>) -> UnsafePointer<UnsafePointer<Int>>
    var fieldTypesAccessor: FieldsTypeAccessor? {
        let offset = pointer.pointee.fieldTypesAccessor
        guard offset != 0 else { return nil }
        let p = UnsafePointer<Int32>.init(pointer)
        let offsetPointer: UnsafePointer<Int> = relativePointer(base: p.advanced(by: 4), offset: offset)
        return unsafeBitCast(offsetPointer, to: FieldsTypeAccessor.self)
    }
}

struct _NominalTypeDescriptor {
    var mangledName: Int32
    var numberOfFields: Int32
    var fieldOffsetVector: Int32
    var fieldNames: Int32
    var fieldTypesAccessor: Int32
}

// MARK: _Measurable

typealias Byte = Int8

public protocol _Measurable {}
extension _Measurable {
    
    // locate the head of a struct type object in memory
    mutating func headPointerOfStruct() -> UnsafeMutablePointer<Byte> {
        return withUnsafeMutablePointer(to: &self) { UnsafeMutableRawPointer($0).bindMemory(to: Byte.self, capacity: MemoryLayout<Self>.stride) }
    }
    
    // locating the head of a class type object in memory
    mutating func headPointerOfClass() -> UnsafeMutablePointer<Byte> {
        let opaquePointer = Unmanaged.passUnretained(self as AnyObject).toOpaque()
        let mutableTypedPointer = opaquePointer.bindMemory(to: Byte.self, capacity: MemoryLayout<Self>.stride)
        return UnsafeMutablePointer<Byte>.init(mutableTypedPointer)
    }
    
    // locating the head of an object
    mutating func headerPointer() -> UnsafeMutablePointer<Byte> { return Self.self is AnyClass ? headPointerOfClass() : headPointerOfStruct() }
    
    func isNSObjectType() -> Bool { return (type(of: self) as? NSObject.Type) != nil }
    
    func getBridgedPropertyList() -> Set<String> {
        guard let anyclass = type(of: self) as? AnyClass else { return [] }
        return _getBridgedPropertyList(anyClass: anyclass)
    }
    
    private func _getBridgedPropertyList(anyClass: AnyClass) -> Set<String> {
        if !(anyClass is GSJSON.Type) { return [] }
        var propertyList = Set<String>.init()
        if let superclass = class_getSuperclass(anyClass), superclass != NSObject.self {
            propertyList = propertyList.union(_getBridgedPropertyList(anyClass: superclass))
        }
        
        let count = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        if let props = class_copyPropertyList(anyClass, count) {
            (0..<count.pointee).forEach {
                propertyList.insert(String.init(cString: property_getName(props.advanced(by: Int($0)).pointee)))
            }
            free(props)
        }
        
        free(count)
        return propertyList
    }
    
    // memory size occupy by self object
    static func size() -> Int { return MemoryLayout<Self>.size }
    // align
    static func align() -> Int { return MemoryLayout<Self>.alignment }
    // Returns the offset to the next integer that is greater than
    // or equal to Value and is a multiple of Align. Align must be
    // non-zero.
    static func offsetToAlignment(value: Int, align: Int) -> Int { let m = value % align; return m == 0 ? 0 : (align - m) }
}

// MARK: _Transformable

public protocol _Transformable: _Measurable {}
extension _Transformable {
    
    static func transform(from object: Any) -> Self? {
        if let typedObject = object as? Self { return typedObject }
        switch self {
        case let type as _ExtendCustomBasicType.Type:
            return type._transform(from: object) as? Self
        case let type as _BuiltInBridgeType.Type:
            return type._transform(from: object) as? Self
        case let type as _BuiltInBasicType.Type:
            return type._transform(from: object) as? Self
        case let type as _RawEnumProtocol.Type:
            return type._transform(from: object) as? Self
        case let type as _ExtendCustomModelType.Type:
            return type._transform(from: object) as? Self
        default:
            return nil
        }
    }
    
    func plainValue() -> Any? {
        switch self {
        case let rawValue as _ExtendCustomBasicType:
            return rawValue._plainValue()
        case let rawValue as _BuiltInBridgeType:
            return rawValue._plainValue()
        case let rawValue as _BuiltInBasicType:
            return rawValue._plainValue()
        case let rawValue as _RawEnumProtocol:
            return rawValue._plainValue()
        case let rawValue as _ExtendCustomModelType:
            return rawValue._plainValue()
        default:
            return nil
        }
    }
}

// MARK: _ExtendCustomBasicType

public protocol _ExtendCustomBasicType: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}

// MARK: _BuiltInBridgeType

protocol _BuiltInBridgeType: _Transformable {
    static func _transform(from object: Any) -> _BuiltInBridgeType?
    func _plainValue() -> Any?
}
extension NSString: _BuiltInBridgeType {
    
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        if let str = String.transform(from: object) { return NSString.init(string: str) }
        else { return nil }
    }
    
    func _plainValue() -> Any? { return self }
}

extension NSNumber: _BuiltInBridgeType {
    
    static func _transform(from object: Any) -> _BuiltInBridgeType? {
        switch object {
        case let num as NSNumber: return num
        case let str as NSString:
            let lowercase = str.lowercased
            if lowercase == "true" {
                return NSNumber(booleanLiteral: true)
            } else if lowercase == "false" {
                return NSNumber(booleanLiteral: false)
            } else {
                // normal number
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                return formatter.number(from: str as String)
            }
        default: return nil
        }
    }
    
    func _plainValue() -> Any? { return self }
}

extension NSArray: _BuiltInBridgeType {
    
    static func _transform(from object: Any) -> _BuiltInBridgeType? { return object as? NSArray }
    func _plainValue() -> Any? { return (self as? Array<Any>)?.plainValue() }
}

extension NSDictionary: _BuiltInBridgeType {
    
    static func _transform(from object: Any) -> _BuiltInBridgeType? { return object as? NSDictionary }
    func _plainValue() -> Any? { return (self as? Dictionary<String, Any>).plainValue() }
}

// MARK: _BuiltInBasicType

protocol _BuiltInBasicType: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}
protocol IntegerPropertyProtocol: FixedWidthInteger, _BuiltInBasicType {
    init?(_ text: String, radix: Int)
    init(_ number: NSNumber)
}

extension IntegerPropertyProtocol {
    
    public static func _transform(from object: Any) -> Self? {
        switch object {
        case let str as String: return Self(str, radix: 10)
        case let num as NSNumber: return Self(num)
        default: return nil
        }
    }
        
    public func _plainValue() -> Any? { return self }
}

extension Int: IntegerPropertyProtocol {}
extension UInt: IntegerPropertyProtocol {}
extension Int8: IntegerPropertyProtocol {}
extension Int16: IntegerPropertyProtocol {}
extension Int32: IntegerPropertyProtocol {}
extension Int64: IntegerPropertyProtocol {}
extension UInt8: IntegerPropertyProtocol {}
extension UInt16: IntegerPropertyProtocol {}
extension UInt32: IntegerPropertyProtocol {}
extension UInt64: IntegerPropertyProtocol {}
extension Bool: _BuiltInBasicType {
    
    public static func _transform(from object: Any) -> Bool? {
        switch object {
        case let str as NSString:
            let lowerCase = str.lowercased
            if ["0", "false"].contains(lowerCase) { return false }
            if ["1", "true"].contains(lowerCase) { return true }
            return nil
        case let num as NSNumber: return num.boolValue
        default: return nil
        }
    }
    
    public func _plainValue() -> Any? { return self }
}

protocol FloatPropertyProtocol: _BuiltInBasicType, LosslessStringConvertible { init(_ number: NSNumber) }
extension FloatPropertyProtocol {
    
    public static func _transform(from object: Any) -> Self? {
        switch object {
        case let str as String: return Self(str)
        case let num as NSNumber: return Self(num)
        default: return nil
        }
    }
    
    public func _plainValue() -> Any? { return self }
}

extension Float: FloatPropertyProtocol {}
extension Double: FloatPropertyProtocol {}

extension String: _BuiltInBasicType {
    
    public static func _transform(from object: Any) -> String? {
        switch object {
        case let str as String: return str
        case let num as NSNumber:
            if NSStringFromClass(type(of: num)) == "__NSCFBoolean" {
                return num.boolValue ? "true" : "false"
            } else { return num.stringValue }
        case _ as NSNull: return nil
        default: return "\(object)"
        }
    }
    
    public func _plainValue() -> Any? { return self }
}

extension Optional: _BuiltInBasicType {
    
    public static func _transform(from object: Any) -> Optional? {
        if let value = (Wrapped.self as? _Transformable.Type)?.transform(from: object) as? Wrapped { return Optional.init(value) }
        else if let value = object as? Wrapped { return Optional.init(value) }
        else { return nil }
    }
    
    public func _plainValue() -> Any? {
        if let value = self.map({ return $0 as Any }) {
            if let transformable = value as? _Transformable {
                return transformable.plainValue()
            } else { return value }
        } else { return nil }
    }
}

extension ImplicitlyUnwrappedOptional: _BuiltInBasicType {

    public static func _transform(from object: Any) -> ImplicitlyUnwrappedOptional? {
        if let value = (Wrapped.self as? _Transformable.Type)?.transform(from: object) as? Wrapped { return ImplicitlyUnwrappedOptional.init(value) }
        else if let value = object as? Wrapped { return ImplicitlyUnwrappedOptional.init(value) }
        else { return nil }
    }

    public func _plainValue() -> Any? {
        if let value = (self == nil ? nil : self!) {
            if let transformable = value as? _Transformable {
                return transformable.plainValue()
            } else { return value }
        } else { return nil }
    }
}

extension Dictionary: _BuiltInBasicType {

    public static func _transform(from object: Any) -> Dictionary<Key, Value>? {
        guard let dic = object as? [String: Any] else { return nil }
        var result = [Key: Value].init()
        dic.forEach {
            if let key = $0.key as? Key {
                if let value = (Value.self as? _Transformable.Type)?.transform(from: $0.value) as? Value {
                    result[key] = value
                } else if let value = $0.value as? Value {
                    result[key] = value
                }
            }
        }

        return result
    }

    public func _plainValue() -> Any? {
        var result = [String: Any].init()
        forEach {
            if let key = $0.key as? String,
                let transformable = $0.value as? _Transformable,
                let value = transformable.plainValue() {
                result[key] = value
            }
        }

        return result
    }
}

extension Collection {
    
    static func _collectionTransform(from object: Any) -> [Iterator.Element]? {
        guard let arr = object as? [Any] else { return nil }
        typealias Element = Iterator.Element
        var result = [Element].init()
        arr.forEach {
            if let element = (Element.self as? _Transformable.Type)?.transform(from: $0) as? Element {
                result.append(element)
            } else if let element = $0 as? Element {
                result.append(element)
            }
        }
        
        return result
    }
    
    func _collectionPlainValue() -> Any? {
        var result = [Any].init()
        forEach {
            if let transformable = $0 as? _Transformable, let value = transformable.plainValue() {
                result.append(value)
            }
        }
        
        return result
    }
}

extension Array: _BuiltInBasicType {
    
    public static func _transform(from object: Any) -> Array<Element>? { return _collectionTransform(from: object) }
    public func _plainValue() -> Any? { return _collectionPlainValue() }
}

extension Set: _BuiltInBasicType {
    
    public static func _transform(from object: Any) -> Set<Element>? {
        if let arr = _collectionTransform(from: object) { return Set.init(arr) }
        else { return nil }
    }
    
    public func _plainValue() -> Any? { return _collectionPlainValue() }
}

// MARK: _RawEnumProtocol

public protocol _RawEnumProtocol: _Transformable {
    static func _transform(from object: Any) -> Self?
    func _plainValue() -> Any?
}
extension RawRepresentable where Self: _RawEnumProtocol {
    
    public static func _transform(from object: Any) -> Self? {
        guard let rawValue = (RawValue.self as? _Transformable.Type)?.transform(from: object) as? RawValue else { return nil }
        return Self.init(rawValue: rawValue )
    }
    
    public func _plainValue() -> Any? { return self.rawValue }
}

// MARK: _ExtendCustomModelType

struct PropertyInfo {
    let key: String
    let type: Any.Type
    let address: UnsafeMutableRawPointer
    let bridged: Bool
}


public protocol _ExtendCustomModelType: _Transformable {
    init()
    mutating func mapping(mapper: Mapper)
    mutating func didFinishMapping()
}

extension _ExtendCustomModelType {
    public mutating func mapping(mapper: Mapper) {}
    public mutating func didFinishMapping() {}
}

fileprivate func getRawValueFrom(dict: [String: Any], property: PropertyInfo, mapper: Mapper) -> Any? {
    if let mappingHandler = mapper.getMappingHandler(key: property.address.hashValue) {
        if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
            for mappingPath in mappingPaths {
                if let _value = dict.findValueBy(path: mappingPath) {
                    return _value
                }
            }
            return nil
        }
    }
    
    return dict[property.key]
}

fileprivate func convertValue(rawValue: Any, property: PropertyInfo, mapper: Mapper) -> Any? {
    if let mappingHandler = mapper.getMappingHandler(key: property.address.hashValue), let transformer = mappingHandler.assignmentClosure {
        return transformer(rawValue)
    }
    if let transformableType = property.type as? _Transformable.Type {
        return transformableType.transform(from: rawValue)
    } else {
        return extensions(of: property.type).takeValue(from: rawValue)
    }
}

fileprivate func assignProperty(convertedValue: Any, instance: _ExtendCustomModelType, property: PropertyInfo) {
    if property.bridged {
        (instance as! NSObject).setValue(convertedValue, forKey: property.key)
    } else {
        extensions(of: property.type).write(convertedValue, to: property.address)
    }
}

fileprivate func readAllChildrenFrom(mirror: Mirror) -> [(String, Any)] {
    var children = [(label: String?, value: Any)].init()
    guard let mirrorChildrenCollection = AnyRandomAccessCollection.init(mirror.children) else { return [] }
    children += mirrorChildrenCollection
    var currentMirror = mirror
    while let superclassChildren = currentMirror.superclassMirror?.children {
        let randomCollection = AnyRandomAccessCollection(superclassChildren)!
        children += randomCollection
        currentMirror = currentMirror.superclassMirror!
    }
    
    var result = [(String, Any)]()
    children.forEach { (child) in
        if let _label = child.label { result.append((_label, child.value)) }
    }
    return result
}

fileprivate func merge(children: [(String, Any)], propertyInfos: [PropertyInfo]) -> [String: (Any, PropertyInfo?)] {
    var infoDict = [String: PropertyInfo]()
    propertyInfos.forEach { (info) in
        infoDict[info.key] = info
    }
    
    var result = [String: (Any, PropertyInfo?)]()
    children.forEach { (child) in
        result[child.0] = (child.1, infoDict[child.0])
    }
    return result
}

extension NSObject {
    static func createInstance() -> NSObject {
        return self.init()
    }
}

extension _ExtendCustomModelType {
    
    static func _transform(from object: Any) -> Self? {
        if let dict = object as? [String: Any] {
            return _transform(dict: dict) as? Self
        } else { return nil }
    }
    
    fileprivate static func _transform(dict: [String: Any]) -> _ExtendCustomModelType? {
        var instance: Self
        if let _nsType = Self.self as? NSObject.Type {
            instance = _nsType.createInstance() as! Self
        } else { instance = Self.init() }
        
        _transform(dict: dict, to: &instance)
        instance.didFinishMapping()
        return instance
    }
    
    fileprivate static func _transform(dict: [String: Any], to instance: inout Self) {
        guard let properties = getProperties(forType: Self.self) else { return }
        // do user-specified mapping first
        let mapper = Mapper.init()
        instance.mapping(mapper: mapper)
        // get head addr
        let rawPointer = instance.headerPointer()
        let instanceIsNsObject = instance.isNSObjectType()
        let bridgedPropertyList = instance.getBridgedPropertyList()
        properties.forEach {
            let isBridgedProperty = instanceIsNsObject && bridgedPropertyList.contains($0.key)
            let propAddr = rawPointer.advanced(by: $0.offset)
            if mapper.propertyExcluded(key: propAddr.hashValue) { return }
            
            let propertyDetail = PropertyInfo.init(key: $0.key, type: $0.type, address: propAddr, bridged: isBridgedProperty)
            if let rawValue = getRawValueFrom(dict: dict, property: propertyDetail, mapper: mapper) {
                if let convertedValue = convertValue(rawValue: rawValue, property: propertyDetail, mapper: mapper) {
                    assignProperty(convertedValue: convertedValue, instance: instance, property: propertyDetail)
                    return
                }
            }
        }
    }
    
    func _plainValue() -> Any? {
        return Self._serializeAny(object: self)
    }
    
    fileprivate static func _serializeAny(object: _Transformable) -> Any? {
        
        let mirror = Mirror(reflecting: object)
        
        guard let displayStyle = mirror.displayStyle else {
            return object.plainValue()
        }
        
        // after filtered by protocols above, now we expect the type is pure struct/class
        switch displayStyle {
        case .class, .struct:
            let mapper = Mapper()
            // do user-specified mapping first
            if !(object is _ExtendCustomModelType) { return object }
            
            let children = readAllChildrenFrom(mirror: mirror)
            
            guard let properties = getProperties(forType: type(of: object)) else { return nil }
            
            var mutableObject = object as! _ExtendCustomModelType
            let instanceIsNsObject = mutableObject.isNSObjectType()
            let head = mutableObject.headerPointer()
            let bridgedProperty = mutableObject.getBridgedPropertyList()
            let propertyInfos = properties.map({ (desc) -> PropertyInfo in
                return PropertyInfo(key: desc.key, type: desc.type, address: head.advanced(by: desc.offset),
                                    bridged: instanceIsNsObject && bridgedProperty.contains(desc.key))
            })
            
            mutableObject.mapping(mapper: mapper)
            
            let requiredInfo = merge(children: children, propertyInfos: propertyInfos)
            
            return _serializeModelObject(instance: mutableObject, properties: requiredInfo, mapper: mapper) as Any
        default:
            return object.plainValue()
        }
    }
    
    private static func _serializeModelObject(instance: _ExtendCustomModelType, properties: [String: (Any, PropertyInfo?)], mapper: Mapper) -> [String: Any] {
        var dict = [String: Any]()
        for (key, property) in properties {
            var realKey = key
            var realValue = property.0
            
            if let info = property.1 {
                if info.bridged, let _value = (instance as! NSObject).value(forKey: key) {
                    realValue = _value
                }
                
                if mapper.propertyExcluded(key: info.address.hashValue) {
                    continue
                }
                
                if let mappingHandler = mapper.getMappingHandler(key: info.address.hashValue) {
                    // if specific key is set, replace the label
                    if let mappingPaths = mappingHandler.mappingPaths, mappingPaths.count > 0 {
                        // take the first path, last segment if more than one
                        realKey = mappingPaths[0].segments.last!
                    }
                    
                    if let transformer = mappingHandler.takeValueClosure {
                        if let _transformedValue = transformer(realValue) {
                            dict[realKey] = _transformedValue
                        }
                        continue
                    }
                }
            }
            
            if let typedValue = realValue as? _Transformable {
                if let result = self._serializeAny(object: typedValue) {
                    dict[realKey] = result
                    continue
                }
            }
        }
        return dict
    }
}

public class Mapper {
    
    private var mappingHandlers = [Int: MappingPropertyHandler].init()
    private var excludeProperties = [Int].init()
    
    internal func getMappingHandler(key: Int) -> MappingPropertyHandler? { return mappingHandlers[key] }
    internal func propertyExcluded(key: Int) -> Bool { return excludeProperties.contains(key) }
    
    public func specify<T>(property: inout T, name: String) {
        specify(property: &property, name: name, converter: nil)
    }
    
    public func specify<T>(property: inout T, converter: @escaping (String) -> T) {
        specify(property: &property, name: nil, converter: converter)
    }
    
    public func specify<T>(property: inout T, name: String?, converter: ((String) -> T)?) {
        let key = withUnsafePointer(to: &property, { return $0 }).hashValue
        let names = (name == nil ? nil : [name!])
        if let _converter = converter {
            let assignmentClosure = { (jsonValue: Any?) -> Any? in
                if let _value = jsonValue{
                    if let object = _value as? NSObject{
                        if let str = String.transform(from: object){
                            return _converter(str)
                        }
                    }
                }
                return nil
            }
            mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: assignmentClosure, takeValueClosure: nil)
        } else {
            mappingHandlers[key] = MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil)
        }
    }
    
    public func exclude<T>(property: inout T) {
        _exclude(property: &property)
    }
    
    fileprivate func addCustomMapping(key: Int, mappingInfo: MappingPropertyHandler) {
        self.mappingHandlers[key] = mappingInfo
    }
    
    fileprivate func _exclude<T>(property: inout T) {
        excludeProperties.append(withUnsafePointer(to: &property, { return $0 }).hashValue)
    }
}

infix operator <-- : LogicalConjunctionPrecedence

public func <-- <T>(property: inout T, name: String) -> CustomMappingKeyValueTuple {
    return property <-- [name]
}

public func <-- <T>(property: inout T, names: [String]) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = pointer.hashValue
    return (key, MappingPropertyHandler(rawPaths: names, assignmentClosure: nil, takeValueClosure: nil))
}

// MARK: non-optional properties
public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: Transform) -> CustomMappingKeyValueTuple {
    return property <-- (nil, transformer)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    let names = (transformer.0 == nil ? [] : [transformer.0!])
    return property <-- (names, transformer.1)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = pointer.hashValue
    let assignmentClosure = { (jsonValue: Any?) -> Transform.Object? in
        return transformer.1?.transformFromJSON(jsonValue)
    }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object {
            return transformer.1?.transformToJSON(_value) as Any
        }
        return nil
    }
    return (key, MappingPropertyHandler(rawPaths: transformer.0, assignmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

// MARK: optional properties
public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: Transform) -> CustomMappingKeyValueTuple {
    return property <-- (nil, transformer)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    let names = (transformer.0 == nil ? [] : [transformer.0!])
    return property <-- (names, transformer.1)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object?, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = pointer.hashValue
    let assignmentClosure = { (jsonValue: Any?) -> Any? in
        return transformer.1?.transformFromJSON(jsonValue)
    }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object {
            return transformer.1?.transformToJSON(_value) as Any
        }
        return nil
    }
    return (key, MappingPropertyHandler(rawPaths: transformer.0, assignmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

// MARK: implicitly unwrap optional properties
public func <-- <Transform: TransformType>(property: inout Transform.Object!, transformer: Transform) -> CustomMappingKeyValueTuple {
    return property <-- (nil, transformer)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object!, transformer: (String?, Transform?)) -> CustomMappingKeyValueTuple {
    let names = (transformer.0 == nil ? [] : [transformer.0!])
    return property <-- (names, transformer.1)
}

public func <-- <Transform: TransformType>(property: inout Transform.Object!, transformer: ([String], Transform?)) -> CustomMappingKeyValueTuple {
    let pointer = withUnsafePointer(to: &property, { return $0 })
    let key = pointer.hashValue
    let assignmentClosure = { (jsonValue: Any?) in
        return transformer.1?.transformFromJSON(jsonValue)
    }
    let takeValueClosure = { (objectValue: Any?) -> Any? in
        if let _value = objectValue as? Transform.Object {
            return transformer.1?.transformToJSON(_value) as Any
        }
        return nil
    }
    return (key, MappingPropertyHandler(rawPaths: transformer.0, assignmentClosure: assignmentClosure, takeValueClosure: takeValueClosure))
}

infix operator <<< : AssignmentPrecedence

public func <<< (mapper: Mapper, mapping: CustomMappingKeyValueTuple) {
    mapper.addCustomMapping(key: mapping.0, mappingInfo: mapping.1)
}

public func <<< (mapper: Mapper, mappings: [CustomMappingKeyValueTuple]) {
    mappings.forEach { (mapping) in
        mapper.addCustomMapping(key: mapping.0, mappingInfo: mapping.1)
    }
}

infix operator >>> : AssignmentPrecedence

public func >>> <T> (mapper: Mapper, property: inout T) {
    mapper._exclude(property: &property)
}

public class MappingPropertyHandler {
    
    var mappingPaths: [MappingPath]?
    var assignmentClosure: ((Any?) -> (Any?))?
    var takeValueClosure: ((Any?) -> (Any?))?
    
    public init(rawPaths: [String]?, assignmentClosure: ((Any?) -> (Any?))?, takeValueClosure: ((Any?) -> (Any?))?) {
        let mappingPaths = (rawPaths ?? []).map { MappingPath.buildFrom(rawPath: $0) }.filter { $0.segments.count > 0 }
        if mappingPaths.count > 0 { self.mappingPaths = mappingPaths }
        self.assignmentClosure = assignmentClosure
        self.takeValueClosure = takeValueClosure
    }
}

public typealias CustomMappingKeyValueTuple = (Int, MappingPropertyHandler)

struct MappingPath {
    
    var segments: [String]
    
    static func buildFrom(rawPath: String) -> MappingPath {
        let regex = try! NSRegularExpression(pattern: "(?<![\\\\])\\.")
        let nsString = rawPath as NSString
        let results = regex.matches(in: rawPath, range: NSRange(location: 0, length: nsString.length))
        var splitPoints = results.map { $0.range.location }
        
        var curPos = 0
        var pathArr = [String]()
        splitPoints.append(nsString.length)
        splitPoints.forEach({ (point) in
            let start = rawPath.index(rawPath.startIndex, offsetBy: curPos)
            let end = rawPath.index(rawPath.startIndex, offsetBy: point)
            let subPath = String(rawPath[start ..< end]).replacingOccurrences(of: "\\.", with: ".")
            if !subPath.isEmpty {
                pathArr.append(subPath)
            }
            curPos = point + 1
        })
        return MappingPath(segments: pathArr)
    }
}

extension Dictionary where Key == String, Value: Any {
    
    func findValueBy(path: MappingPath) -> Any? {
        var currentDict: [String: Any]? = self
        var lastValue: Any?
        path.segments.forEach { (segment) in
            lastValue = currentDict?[segment]
            currentDict = currentDict?[segment] as? [String: Any]
        }
        return lastValue
    }
}

// MARK: TransformType

public protocol TransformType {
    associatedtype Object
    associatedtype JSON
    
    func transformFromJSON(_ value: Any?) -> Object?
    func transformToJSON(_ value: Object?) -> JSON?
}

// MARK: DataTransform

open class DataTransform: TransformType {
    
    public typealias Object = Data
    public typealias JSON = String
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> Data? {
        guard let string = value as? String else { return nil }
        return Data.init(base64Encoded: string)
    }
    
    public func transformToJSON(_ value: Data?) -> String? {
        guard let data = value else { return nil }
        return data.base64EncodedString()
    }
}

// MARK: DateFormatterTransform

open class DateFormatterTransform: TransformType {
    
    public typealias Object = Date
    public typealias JSON = String
    
    public let dateFormatter: DateFormatter
    
    public init(dateFormatter: DateFormatter) { self.dateFormatter = dateFormatter }
    
    open func transformFromJSON(_ value: Any?) -> Date? {
        guard let dateString = value as? String else { return nil }
        return dateFormatter.date(from: dateString)
    }
    
    open func transformToJSON(_ value: Date?) -> String? {
        guard let date = value else { return nil }
        return dateFormatter.string(from: date)
    }
}

open class CustomDateFormatTransform: DateFormatterTransform {
    
    public init(formatString: String) {
        super.init(dateFormatter: DateFormatter.init().then {
            $0.dateFormat = formatString
            $0.locale = Locale.init(identifier: "en_US_POSIX")
        })
        
    }
}

open class ISO8601DateTransform: DateFormatterTransform {
    
    public init() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        super.init(dateFormatter: formatter)
    }
    
}


// MARK: EnumTransform

open class EnumTransform<T: RawRepresentable>: TransformType {
    
    public typealias Object = T
    public typealias JSON = T.RawValue
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> T? {
        guard let raw = value as? T.RawValue else { return nil }
        return T(rawValue: raw)
    }
    
    public func transformToJSON(_ value: T?) -> T.RawValue? {
        guard let obj = value else { return nil }
        return obj.rawValue
    }
}

//// MARK: NSDecimalNumberTransform

open class NSDecimalNumberTransform: TransformType {
    
    public typealias Object = NSDecimalNumber
    public typealias JSON = String
    public init() {}
    
    public func transformFromJSON(_ value: Any?) -> NSDecimalNumber? {
        if let string = value as? String { return NSDecimalNumber.init(string: string) }
        if let double = value as? Double { return NSDecimalNumber.init(value: double) }
        return nil
    }
    
    public func transformToJSON(_ value: NSDecimalNumber?) -> String? {
        guard let value = value else { return nil }
        return value.description
    }
}

// MARK: TransformOf<ObjectType, JSONType>

open class TransformOf<ObjectType, JSONType>: TransformType {
    
    public typealias Object = ObjectType
    public typealias JSON = JSONType
    private let fromJSON: (JSONType?) -> ObjectType?
    private let toJSON: (ObjectType?) -> JSONType?
    
    public init(fromJSON: @escaping(JSONType?) -> ObjectType?, toJSON: @escaping (ObjectType?) -> JSONType?) {
        self.fromJSON = fromJSON
        self.toJSON = toJSON
    }
    
    public func transformFromJSON(_ value: Any?) -> ObjectType? { return fromJSON(value as? JSONType) }
    public func transformToJSON(_ value: ObjectType?) -> JSONType? { return toJSON(value) }
}

// MARK: URLTransform

open class URLTransform: TransformType {
    
    public typealias Object = URL
    public typealias JSON = String
    private let shouldEncodeURLString: Bool
    public init(shouldEncodeURLString: Bool = true) { self.shouldEncodeURLString = shouldEncodeURLString }
    
    public func transformFromJSON(_ value: Any?) -> URL? {
        guard let urlString = value as? String else { return nil }
        if !shouldEncodeURLString { return URL.init(string: urlString) }
        guard let escapedURLString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return nil }
        return URL.init(string: escapedURLString)
    }
    
    public func transformToJSON(_ value: URL?) -> String? {
        guard let url = value else { return nil }
        return url.absoluteString
    }
}

// MARK: Other Extensions

protocol UTF8Initializable {
    init?(validatingUTF8: UnsafePointer<CChar>)
}

extension String: UTF8Initializable {}

extension Array where Element: UTF8Initializable {
    init(utf8Strings: UnsafePointer<CChar>) {
        var strings = [Element]()
        var pointer = utf8Strings
        while let string = Element(validatingUTF8: pointer) {
            strings.append(string)
            while pointer.pointee != 0 { pointer.advance() }
            pointer.advance()
            guard pointer.pointee != 0 else { break }
        }
        
        self = strings
    }
}

extension Strideable {
    mutating func advance() { self = advanced(by: 1) }
}

extension UnsafePointer {
    
    init<T>(_ pointer: UnsafePointer<T>) { self = UnsafeRawPointer(pointer).assumingMemoryBound(to: Pointee.self) }
}

func relativePointer<T, U, V>(base: UnsafePointer<T>, offset: U) -> UnsafePointer<V> where U: FixedWidthInteger {
    return UnsafeRawPointer(base).advanced(by: Int(offset)).assumingMemoryBound(to: V.self)
}
