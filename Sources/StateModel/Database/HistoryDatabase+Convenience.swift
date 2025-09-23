import Foundation

extension HistoryDatabase {

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    public func all<Instance: ModelProtocol>(at date: Date?, where predicate: (Instance) -> Bool) -> [Instance] where Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        return all(model: Instance.modelId, at: date) { instanceId, status, _ in
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
     - Parameter path: The path of the property
     - Parameter type: The type of value to get
     - Returns: The value of the property, if one exists
     */
    @inline(__always)
    public func get<Value>(_ path: KeyPath, at date: Date?, of type: Value.Type) -> (value: Value, date: Date)? where Value: DatabaseValue {
        get(path, at: date)
    }

    /**
     Set the value for a specific property.
     - Parameter value: The new value to set for the property
     - Parameter path: The path of the property
     - Parameter type: The type of the value to set
     */
    @inline(__always)
    func set<Value>(_ value: Value, for path: KeyPath, at date: Date?, of type: Value.Type) where Value: DatabaseValue {
        set(value, for: path, at: date)
    }

    // MARK: Instances

    /**
     Get all instances of a given model type.
     - Returns: The instances in the database that are not deleted
     */
    @inline(__always)
    public func all<Instance>(at date: Date?, of type: Instance.Type = Instance.self) -> [Instance] where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        all(at: date) { _ in true }
    }

    /**
     Get all instances of a given model type that fullfil the predicate.
     - Parameter model: The model type to select.
     - Parameter predicate: The filter function to apply.
     - Returns: The instances in the database that match the predicate
     */
    func all<Instance>(_ model: Instance.Type, at date: Date?, where predicate: (Instance) -> Bool) -> [Instance] where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        all(at: date, where: predicate)
    }

    public func create<Instance>(id: InstanceKey, at date: Date?, of type: Instance.Type = Instance.self) -> Instance where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        set(InstanceStatus.created, model: Instance.modelId, instance: id, property: PropertyKey.instanceId, at: date)
        return .init(database: self, id: id)
    }

    /**
     Get an instance of a model by its id.
     - Note: This function also returns instances that have previously been deleted.
     Check the `status` property on the model, or alternatively use ``active(id:)`` to only query for non-deleted instances.
     */
    public func get<Instance>(id: InstanceKey, at date: Date?, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        let path = Path(model: Instance.modelId, instance: id, property: PropertyKey.instanceId)
        guard get(path, at: date, of: InstanceStatus.self) != nil else {
            return nil
        }
        return .init(database: self, id: id)
    }

    public func active<Instance>(id: InstanceKey, at date: Date?, of type: Instance.Type = Instance.self) -> Instance? where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        let path = Path(model: Instance.modelId, instance: id, property: PropertyKey.instanceId)
        guard let status: InstanceStatus = get(path, at: date)?.value, status == .created else {
            return nil
        }
        return .init(database: self, id: id)
    }

    /**
     Get an existing instance of a model or create it.
     - Note: If an instance exists, but is deleted, it will still be returned.
     */
    public func getOrCreate<Instance>(id: InstanceKey, at date: Date?, of type: Instance.Type = Instance.self) -> Instance where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        get(id: id, at: date) ?? create(id: id, at: date)
    }

    /**
     Delete a specific instance.
     - Parameter instance: The instance to delete
     */
    public func delete<Instance>(_ instance: Instance, at date: Date?) where Instance: ModelProtocol, Instance.ModelKey == ModelKey, Instance.InstanceKey == InstanceKey, Instance.PropertyKey == PropertyKey {
        let path = Path(model: Instance.modelId, instance: instance.id, property: PropertyKey.instanceId)
        set(InstanceStatus.deleted, for: path, at: date)
    }
}
