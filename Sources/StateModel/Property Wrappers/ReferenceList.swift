
/**
 A property wrapper to track a list of referenced instances.

 Use this wrapper for properties that contain a sequence of objects that are also models.

 ```swift
 @Model(id: 1)
 class MyModel {

     @ReferenceList(id: 1)
     var list: [Nested]
 }
 ```

 The wrapper will link the sequence to the database, so that any changes to the sequence are persisted.

`@ReferenceList` can be used with any sequence type that conforms to `SequenceInitializable`, like `Array` or `Set`.
 Internally, the property will be stored as an ordered list of integer ids.
 */
@propertyWrapper
public struct ReferenceList<S: SequenceInitializable> where S.Element: ModelProtocol {

    /// The unique id of the property for the model
    let id: PropertyKey

    /**
     The wrapped value will be queried from the database using the subscript.
     - Warning: Directly accessing the property will cause a `fatalError`, since the wrapper requires access to the database reference of the enclosing model.
     */
    @available(*, unavailable, message: "@ReferenceList can only be used within models that provide a database reference")
    public var wrappedValue: S {
        get { fatalError() }
        set { fatalError() }
    }

    /**
     Create a new reference list with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init(id: PropertyKey) {
        self.id = id
    }

    /**
     Create a new reference list with a property id
     - Parameter id: The unique id of the property for the model
     */
    public init<T: RawRepresentable>(id: T) where T.RawValue == PropertyKey {
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
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, S>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, ReferenceList<S>>
    ) -> S {
        get {
            let wrapper = instance[keyPath: storageKeyPath]
            // First get the id of the referenced instance
            let references: [InstanceKey] = instance.get(wrapper.id) ?? []
            return S.init(references.map { instance.database.getOrCreate(id: $0) })
        }
        set {
            let wrapper = instance[keyPath: storageKeyPath]
            instance.set(newValue.map { $0.id }, for: wrapper.id)
        }
    }
}
