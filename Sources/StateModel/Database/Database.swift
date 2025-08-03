
/**
 A database represents the interface to store and retrieve information about models and their data.
 */
public protocol Database: AnyObject {

    /// The type used to uniquely identify different model types in the database
    associatedtype ModelKey: ModelKeyType

    /// The type used to uniquely identify each instance of a model in the database
    associatedtype InstanceKey: InstanceKeyType

    /// The type used to uniquely identify the properties of models in the database
    associatedtype PropertyKey: PropertyKeyType

    /// The type that identifies each property of a model instance uniquely
    typealias KeyPath = Path<ModelKey, InstanceKey, PropertyKey>

    // MARK: Properties

    /**
     Get the value for a specific property.
     - Parameter path: The unique identifier of the property
     - Returns: The value of the property, if one exists
     */
    func get<Value>(_ path: KeyPath) -> Value? where Value: DatabaseValue

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The unique identifier of the property
     */
    func set<Value>(_ value: Value, for path: KeyPath) where Value: DatabaseValue

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func select<Instance>(where predicate: (Instance) -> Bool) -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self
}

extension Database {

    /**
     Update a property only when it changes, to prevent unnecessary updates.
     */
    public func update<Value>(_ value: Value, for path: KeyPath) where Value: Codable, Value: Equatable {
        if let existing: Value = get(path), value == existing {
            return
        }
        set(value, for: path)
    }

    /**
     Get the value for a specific property.
     - Parameter path: The unique identifier of the property
     - Parameter type: The type of value to get
     - Returns: The value of the property, if one exists
     */
    @inline(__always)
    public func get<Value>(_ keyPath: KeyPath, of type: Value.Type) -> Value? where Value: DatabaseValue {
        get(keyPath)
    }

    // MARK: Instances

    /**
     Get all instances of a given model type.
     - Returns: The instances in the database that are not deleted
     */
    @inline(__always)
    func all<Instance>() -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self {
        select { _ in true }
    }

    /**
     Get all instances of a given model type.
     - Returns: The instances in the database that are not deleted
     */
    @inline(__always)
    public func all<Instance>(of type: Instance.Type) -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self {
        all()
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter model: The model type to select.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func select<Instance>(_ model: Instance.Type, where predicate: (Instance) -> Bool) -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self {
        select(where: predicate)
    }

    public func create<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance where Instance: ModelProtocol, Instance.Storage == Self {
        let path = KeyPath(model: Instance.modelId, instance: id)
        set(InstanceStatus.created, for: path)
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.Storage == Self {
        let path = KeyPath(model: Instance.modelId, instance: id)
        guard get(path, of: InstanceStatus.self) != nil else {
            return nil
        }
        return .init(database: self, id: id)
    }

    public func active<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.Storage == Self {
        let path = KeyPath(model: Instance.modelId, instance: id)
        guard let status: InstanceStatus = get(path), status == .created else {
            return nil
        }
        return .init(database: self, id: id)
    }

    /**
     Get an existing instance of a model or create it.
     - Note: If an instance exists, but is deleted, it will still be returned.
     */
    public func getOrCreate<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance where Instance: ModelProtocol, Instance.Storage == Self {
        get(id: id) ?? create(id: id)
    }

    /**
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    public func delete<Instance>(_ instance: Instance) where Instance: ModelProtocol, Instance.Storage == Self {
        let path = instance.instancePath
        set(InstanceStatus.deleted, for: path)
    }
}
