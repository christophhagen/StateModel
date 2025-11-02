
/**
 A key path identifies each property of a model instance uniquely.

 Model paths are constructed from three components:
 - The model id uniquely identifies each distinct type in the database
 - The instance id uniquely identifies each element of a type
 - The property id uniquely identifies each property of a type

 Together these three parts are used to address and store values in the database.
 */
public struct Path: Hashable {

    /// The unique identifier of the model type
    public let model: ModelKey

    /// The unique identifier of the instance
    public let instance: InstanceKey

    /// The unique identifier of the property
    public let property: PropertyKey

    /**
     Create a new path.
     - Note: Paths are usually not created directly, but automatically constructed by property wrappers like `@Property`.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     */
    public init(model: ModelKey, instance: InstanceKey, property: PropertyKey) {
        self.model = model
        self.instance = instance
        self.property = property
    }

    /**
     Create a new path.
     - Note: Paths are usually not created directly, but automatically constructed by property wrappers like `@Property`.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     */
    public init<T: RawRepresentable>(model: ModelKey, instance: InstanceKey, property: T) where T.RawValue == PropertyKey {
        self.model = model
        self.instance = instance
        self.property = property.rawValue
    }

    /**
     Create a new path for the status of an instance object.

     This path uses ``PropertyKey.instanceId`` as the `property` to signal that this path targets the instance itself.
     - Note: Paths are usually not created directly, but automatically constructed by property wrappers like `@Property`.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     */
    init(model: ModelKey, instance: InstanceKey) {
        self.model = model
        self.instance = instance
        self.property = Int.instanceId
    }
}

extension Path: Comparable {

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.model, lhs.instance, lhs.property) < (rhs.model, rhs.instance, rhs.property)
    }
}

extension Path: CustomStringConvertible {

    public var description: String {
        "\(model).\(instance).\(property)"
    }
}

extension Path: Encodable {

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(model)
        try container.encode(instance)
        try container.encode(property)
    }
}

extension Path: Decodable {

    public init(from decoder: any Decoder) throws {
        var container = try decoder.unkeyedContainer()
        self.model = try container.decode()
        self.instance = try container.decode()
        self.property = try container.decode()
    }
}
