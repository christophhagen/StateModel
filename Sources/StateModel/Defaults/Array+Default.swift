
extension Array: Defaultable {

    /// The default value for an `Array` property is an empty array
    public static var `default`: Self { [] }
}

extension Set: Defaultable {

    /// The default value for a `Set` property is an empty set
    public static var `default`: Self { [] }
}

extension Dictionary: Defaultable {

    /// The default value for a `Dictionary` property is an empty dictionary
    public static var `default`: Self { [:] }
}
