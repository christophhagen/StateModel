
/**
 A property wrapper to track a list of referenced instances.

 ```swift
 class MyModel: Model<MyDatabase> {
     static let modelId = 1

     @ReferenceList(id: 1)
     var list: List<Nested>
 }
 ```
 */
@propertyWrapper
public struct ReferenceList<Value> where Value: ModelProtocol, Value.Storage.PropertyKey: DatabaseValue {

    /// The unique id of the property for the model
    let id: Value.Storage.PropertyKey

    /**
     The wrapped value will be queried from the database using the subscript.
     - Warning: Directly accessing the property will cause a `fatalError`, since the wrapper requires access to the database reference of the enclosing model.
     */
    @available(*, unavailable, message: "@ReferenceList can only used within models that provide a database reference")
    public var wrappedValue: List<Value> {
        get { fatalError() }
        set { fatalError() }
    }

    /**
     Create a new reference list with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init(id: Value.Storage.PropertyKey) {
        self.id = id
    }

    /**
     Create a new reference list with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init<T: RawRepresentable>(id: T) where T.RawValue == Value.Storage.PropertyKey {
        self.id = id.rawValue
    }

    /**
     The value of the property.

     This subscript reads the list references using the database reference of the enclosing model.
     It then returns a list that allows accessing the contained models.
     It also uses the same reference to write the references to the database when the list is changed.
     */
    public static subscript<EnclosingSelf: ModelProtocol>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, List<Value>>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, ReferenceList<Value>>
    ) -> List<Value> where EnclosingSelf.Storage == Value.Storage {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            let propertyPath = EnclosingSelf.Storage.KeyPath(model: EnclosingSelf.modelId, instance: instance.id, property: wrapper.id)
            // First get the id of the referenced instance
            let references: [Value.Storage.InstanceKey] = instance.database.get(propertyPath) ?? []
            return .init(database: instance.database, references: references)
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            let propertyPath = EnclosingSelf.Storage.KeyPath(model: EnclosingSelf.modelId, instance: instance.id, property: wrapper.id)
            instance.database.set(newValue.references, for: propertyPath)
        }
    }
}
