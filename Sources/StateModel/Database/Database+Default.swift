import Foundation


extension Database {

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Parameter type: The type of model to create.
     - Returns: A new model instance of the specified type with the given id.
     */
    public func create<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance {
        set(InstanceStatus.created, for: Instance.statusPath(for: id))
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard get(Instance.statusPath(for: id), of: InstanceStatus.self) != nil else {
            return nil
        }
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    @inline(__always)
    public func get<Instance: ModelProtocol>(id: InstanceKey) -> Instance? {
        get(id: id, of: Instance.self)
    }

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Parameter type: The type of the model
     - Returns: The existing, non-deleted instance, or `nil`
     */
    public func active<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard let status: InstanceStatus = get(Instance.statusPath(for: id)), status == .created else {
            return nil
        }
        return .init(database: self, id: id)
    }

    /**
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    @inline(__always)
    public func delete<Instance: ModelProtocol>(_ instance: Instance) {
        set(InstanceStatus.deleted, for: Instance.statusPath(for: instance.id))
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    public func all<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance] {
        return all(model: Instance.modelId) { instanceId, status in
            guard status == .created else {
                return nil
            }
            let instance = Instance(database: self, id: instanceId)
            guard predicate(instance) else {
                return nil
            }
            return instance
        }
    }

    // MARK: Helper functions

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Returns: The existing, non-deleted instance, or `nil`
     */
    public func active<Instance: ModelProtocol>(id: InstanceKey) -> Instance? {
        active(id: id, of: Instance.self)
    }

    /**
     Get an existing instance of a model or create it.
     - Note: If an instance exists, but is deleted, it will still be returned.
     */
    public func getOrCreate<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance {
        get(id: id) ?? create(id: id)
    }

    /**
     Get an existing instance of a model or create it.
     - Note: If an instance exists, but is deleted, it will still be returned.
     */
    public func getOrCreate<Instance: ModelProtocol>(id: InstanceKey) -> Instance {
        getOrCreate(id: id, of: Instance.self)
    }

    /**
     Get the value for a specific property.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Parameter type: The type of value to get
     - Returns: The value of the property, if one exists
     */
    @inline(__always)
    public func get<Value: DatabaseValue>(model: ModelKey, instance: InstanceKey, property: PropertyKey, of type: Value.Type = Value.self) -> Value? {
        get(.init(model: model, instance: instance, property: property), of: type)
    }

    /**
     Get the value for a specific property.
     - Parameter path: The path of the property- Parameter type: The type of the value.
     - Returns: The value of the property, if one exists

     This function is useful when the type of `Value` may be incorrectly inferred from the context.
     */
    @inline(__always)
    public func get<Value: DatabaseValue>(_ path: Path, of type: Value.Type) -> Value? {
        get(path)
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     */
    @inline(__always)
    public func set<Value: DatabaseValue>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey, of type: Value.Type = Value.self) {
        set(value, for: .init(model: model, instance: instance, property: property))
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     - Parameter type: The type of the value.

     This function is useful when the type of `value` may be incorrectly inferred from the context.
     */
    @inline(__always)
    public func set<Value: DatabaseValue>(_ value: Value, for path: Path, of type: Value.Type) {
        set(value, for: path)
    }

    // MARK: Queries

    /**
     Get all instances of a given model type.
     - Returns: The instances in the database that are not deleted
     */
    @inline(__always)
    public func all<Instance: ModelProtocol>(of type: Instance.Type = Instance.self) -> [Instance] {
        all { _ in true }
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter model: The model type to select.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    @inline(__always)
    public func all<Instance: ModelProtocol>(_ model: Instance.Type, where predicate: (Instance) -> Bool) -> [Instance] {
        all(where: predicate)
    }

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Returns: A new model instance of the specified type with the given id.
     */
    @inline(__always)
    public func create<Instance: ModelProtocol>(id: InstanceKey) -> Instance {
        create(id: id, of: Instance.self)
    }
}
