
extension BinaryFloatingPoint {

    /// The default value for a floating property is  `zero`
    public static var `default`: Self { .zero }
}

extension Double: Defaultable { }
extension Float: Defaultable { }

@available(macOS 11.0, iOS 14.0, watchOS 7.0, tvOS 14.0, *)
extension Float16: Defaultable { }
