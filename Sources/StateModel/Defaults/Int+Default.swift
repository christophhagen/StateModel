
extension AdditiveArithmetic {

    /// The default value when creating an empty property (`zero`)
    public static var `default`: Self { .zero }
}

extension Int: Defaultable { }
extension Int8: Defaultable { }
extension Int16: Defaultable { }
extension Int32: Defaultable { }
extension Int64: Defaultable { }

extension UInt: Defaultable { }
extension UInt8: Defaultable { }
extension UInt16: Defaultable { }
extension UInt32: Defaultable { }
extension UInt64: Defaultable { }
