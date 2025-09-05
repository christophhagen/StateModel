
/**
 A wrapper to reference other model instances.

 ```swift
 class MyModel: Model<MyDatabase> {
     static let modelId = 1

     @Reference(id: 1)
     var ref: Nested?
 }
 ```
 */
@propertyWrapper
public struct Reference<Value> where Value: ModelProtocol {

    /// The unique id of the property for the model
    let id: Value.Storage.PropertyKey

    /**
     The wrapped value will be queried from the database using the subscript.
     - Warning: Directly accessing the property will cause a `fatalError`, since the wrapper requires access to the database reference of the enclosing model.
     */
    @available(*, unavailable, message: "@Reference can only used within models that provide a database reference")
    public var wrappedValue: Value? {
        get { fatalError() }
        set { fatalError() }
    }

    /**
     Create a new property with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init(id: Value.Storage.PropertyKey) {
        self.id = id
    }
    /**
     Create a new property with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init<T: RawRepresentable>(id: T) where T.RawValue == Value.Storage.PropertyKey {
        self.id = id.rawValue
    }

    /**
     The value of the property.

     This subscript reads the model container using the database reference of the enclosing model.
     It also uses the same reference to write changes to the property to the database.
     */
    public static subscript<EnclosingSelf: ModelProtocol>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Reference<Value>>
    ) -> Value? where EnclosingSelf.Storage == Value.Storage {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            // First get the id of the referenced instance
            guard let referenceId: Value.Storage.InstanceKey? = instance.database.get(model: EnclosingSelf.modelId, instance: instance.id, property: wrapper.id, of: Value.Storage.InstanceKey?.self), let referenceId else {
                return nil
            }
            // Then get the instance itself
            // NOTE: If the referenced model is deleted, then we return it here.
            // Otherwise the reference would be invisible, and might unexpectedly
            // point to another object with the same id in the future.

            // What can happen though is that the database has no entry for the reference
            // in which case we simply create the object.
            // This is preferable to having an invisible reference that may pop up in the future.
            return instance.database.getOrCreate(id: referenceId)
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            // It is possible to assign an object that is not stored in the database.
            // In this case the object would be created when the property is accessed.
            instance.database.set(newValue?.id, model: EnclosingSelf.modelId, instance: instance.id, property: wrapper.id)
        }
    }
}
