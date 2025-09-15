import Foundation

extension DatabaseProtocol {

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    public func all<Instance: ModelProtocol>(where predicate: (Instance) -> Bool) -> [Instance] where Instance.Storage == Self {
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
     Get the value for a specific property.
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Parameter type: The type of value to get
     - Returns: The value of the property, if one exists
     */
    @inline(__always)
    public func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey, of type: Value.Type) -> Value? where Value: DatabaseValue {
        get(model: model, instance: instance, property: property)
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter model: The unique identifier of the model type
     - Parameter instance: The unique identifier of the instance
     - Parameter property: The unique identifier of the property
     - Parameter type: The type of the value to set
     */
    @inline(__always)
    func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey, of type: Value.Type) where Value: DatabaseValue {
        set(value, model: model, instance: instance, property: property)
    }

    // MARK: Instances

    /**
     Get all instances of a given model type.
     - Returns: The instances in the database that are not deleted
     */
    @inline(__always)
    public func all<Instance>(of type: Instance.Type = Instance.self) -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self {
        all { _ in true }
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter model: The model type to select.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func all<Instance>(_ model: Instance.Type, where predicate: (Instance) -> Bool) -> [Instance] where Instance: ModelProtocol, Instance.Storage == Self {
        all(where: predicate)
    }

    public func create<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance where Instance: ModelProtocol, Instance.Storage == Self {
        set(InstanceStatus.created, model: Instance.modelId, instance: id, property: PropertyKey.instanceId)
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.Storage == Self {
        guard get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId, of: InstanceStatus.self) != nil else {
            return nil
        }
        return .init(database: self, id: id)
    }

    public func active<Instance>(id: InstanceKey, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.Storage == Self {
        guard let status: InstanceStatus = get(model: Instance.modelId, instance: id, property: PropertyKey.instanceId), status == .created else {
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
        set(InstanceStatus.deleted, model: Instance.modelId, instance: instance.id, property: PropertyKey.instanceId)
    }
}
