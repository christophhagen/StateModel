
/**
 A wrapper for model properties to indicate the key with which they are stored.

 Use the `@Property` wrapper to define properties that are persisted in the database.
 Each property will be wrapped so that any assignment is written to the database, and reading the value will retrieve the current value.

 ```swift
 class MyModel: Model<MyDatabase> {
     static let modelId = 32

     @Property(id: 1)
     var value: Int
 }
 ```

 In this case, the database `MyDatabase` expects the `PropertyKey` to be an integer (`1`).
 Depending on the database implementation, this type may be different.

 It's possible to provide a default value during object creation:

 ```swift
 @Property(id: 1)
 var value: Int = 0
 ```

 `@Property` can be used with any type that conforms to  `Codable`.
 To model relationships to other models, see ``Reference`` and ``ReferenceList``.
 */
@propertyWrapper
public struct Property<Value: DatabaseValue> {

    /// The unique id of the property for the model
    let id: PropertyKey

    /// The default value to use when the database contains no value for the property
    private let defaultValue: Value

    /**
     The wrapped value will be queried from the database using the subscript.
     - Warning: Directly accessing the property will cause a `fatalError`, since the wrapper requires access to the database reference of the enclosing model.
     */
    @available(*, unavailable, message: "@Property can only be used within models that provide a database reference")
    public var wrappedValue: Value {
        get { fatalError() }
        set { fatalError() }
    }

    /**
     Create a new property with a default value derived from the wrapped type.
     - Parameter id: The unique id of the property for the model
     */
    public init(id: PropertyKey) where Value: Defaultable {
        self.id = id
        self.defaultValue = Value.default
    }

    /**
     Create a new property with a default value derived from the wrapped type.
     - Parameter id: The unique id of the property for the model
     */
    public init(id: PropertyKey) where Value: AnyOptional {
        self.id = id
        self.defaultValue = Value.nilValue
    }

    /**
     Create a new property with a default value specified via assignment
     - Parameter wrappedValue: The default value to use when the database contains no value for the property
     - Parameter id: The unique id of the property for the model
     */
    public init(wrappedValue: Value, id: PropertyKey) {
        self.id = id
        self.defaultValue = wrappedValue
    }

    /**
     Create a new property from with a default value derived from the wrapped type.
     - Parameter id: The unique id of the property for the model
     */
    public init<T: RawRepresentable>(id: T) where Value: Defaultable, T.RawValue == PropertyKey {
        self.id = id.rawValue
        self.defaultValue = Value.default
    }

    /**
     Create a new property with an explicit default value.
     - Parameter default: The default value to use when the database contains no value for the property
     - Parameter id: The unique id of the property for the model
     */
    public init(id: PropertyKey, default defaultValue: Value) {
        self.id = id
        self.defaultValue = defaultValue
    }

    /**
     Create a new property with an explicit default value.
     - Parameter default: The default value to use when the database contains no value for the property
     - Parameter id: The unique id of the property for the model
     */
    public init<T: RawRepresentable>(id: T, default defaultValue: Value) where T.RawValue == PropertyKey {
        self.id = id.rawValue
        self.defaultValue = defaultValue
    }

    /**
     The value of the property.

     This subscript reads the property value using the database reference of the enclosing model.
     It also uses the same reference to write assignments to the database.
     */
    public static subscript<EnclosingSelf: ModelProtocol>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Property<Value>>
    ) -> Value {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            return instance.get(wrapper.id) ?? wrapper.defaultValue
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.set(newValue, for: wrapper.id)
        }
    }
}
