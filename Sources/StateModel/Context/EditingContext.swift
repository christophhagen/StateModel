import Foundation

/**
 A temporary context to perform edits to a database, which can be commited all together.
 */
public final class EditingContext<ModelKey,InstanceKey,PropertyKey>: Database<ModelKey,InstanceKey,PropertyKey> where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    /// The database which is being edited
    private unowned let database: Database<ModelKey,InstanceKey,PropertyKey>

    /// The modified values
    ///
    /// - Note: Contains only the most recent values of the edits
    private var modifiedValues: [Path<ModelKey, InstanceKey, PropertyKey>: (value: Any, setter: () -> Void)] = [:]

    init(database: Database<ModelKey,InstanceKey,PropertyKey>) {
        self.database = database
    }

    public override func get<Value>(_ path: KeyPath) -> Value? where Value : Decodable, Value : Encodable {
        if let edited: Value = getFromCache(path) {
            return edited

        }
        return database.get(path)
    }
    
    public override func set<Value>(_ value: Value, for path: KeyPath) where Value : Decodable, Value : Encodable {
        let setter: () -> Void = { [weak self] in
            self?.database.set(value, for: path)
        }
        // Note: Previous edits are overwritten
        modifiedValues[path] = (value, setter)
    }
    
    public override func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        var handledIds: Set<InstanceKey> = []
        let existing: [T] = database.all(model: model) { instance, status in
            handledIds.insert(instance)
            let path = KeyPath(model: model, instance: instance, property: PropertyKey.instanceId)
            if let edited: InstanceStatus = getFromCache(path) {
                return predicate(instance, edited)
            }
            return predicate(instance, status)
        }

        // Find additional instances added to the context
        let additions: [T] = modifiedValues.compactMap { (path, data) in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  !handledIds.contains(path.instance),
                  let status = data.value as? InstanceStatus else {
                return nil
            }
            return predicate(path.instance, status)
        }
        return existing + additions
    }

    private func getFromCache<Value>(_ path: KeyPath) -> Value? where Value : Decodable, Value : Encodable {
        guard let changed = modifiedValues[path] else {
            return nil
        }
        return changed.value as? Value
    }

    /**
     Write all changes made in the context to the database.
     */
    public func commitChanges() {
        for value in modifiedValues.values {
            value.setter()
        }
        discardChanges()
    }

    public func discardChanges() {
        modifiedValues.removeAll()
    }
}
