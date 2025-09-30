import Foundation


extension Database {

    // MARK: Instances

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Returns: A new model instance of the specified type with the given id.
     */
    public func create<Instance: ModelProtocol>(id: InstanceKey) -> Instance {
        create(id: id, of: Instance.self)
    }

    /**
     Create a new instance.

     This function will set the instance status of the provided id to `created`,
     and return the instance.

     - Parameter id: The instance id
     - Parameter type: The type of model to create.
     - Returns: A new model instance of the specified type with the given id.
     */
    public func create<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance {
        set(InstanceStatus.created, model: Instance.modelId, instance: id, property: PropertyKey.instanceId)
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance: ModelProtocol>(id: InstanceKey) -> Instance? {
        get(id: id, of: Instance.self)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId, of: InstanceStatus.self) != nil else {
            return nil
        }
        return .init(database: self, id: id)
    }

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Returns: The existing, non-deleted instance, or `nil`
     */
    public func active<Instance: ModelProtocol>(id: InstanceKey) -> Instance? {
        active(id: id, of: Instance.self)
    }

    /**
     Get an instance via its id, if it exists and is not deleted.
     - Parameter id: The instance id
     - Parameter type: The type of the model
     - Returns: The existing, non-deleted instance, or `nil`
     */
    public func active<Instance: ModelProtocol>(id: InstanceKey, of type: Instance.Type) -> Instance? {
        guard let status: InstanceStatus = get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId), status == .created else {
            return nil
        }
        return .init(database: self, id: id)
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
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    public func delete<Instance: ModelProtocol>(_ instance: Instance) {
        set(InstanceStatus.deleted, model: Instance.modelId, instance: instance.id, property: PropertyKey.instanceId)
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
    func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey, of type: Value.Type) -> Value? where Value: DatabaseValue {
        get(model: model, instance: instance, property: property)
    }
    
    // MARK: Queries

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
    public func all<Instance: ModelProtocol>(_ model: Instance.Type, where predicate: (Instance) -> Bool) -> [Instance] {
        all(where: predicate)
    }
}
