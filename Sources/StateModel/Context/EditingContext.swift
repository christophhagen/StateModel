import Foundation

/**
 A temporary context to perform edits to a database, which can be commited all together.
 */
public final class EditingContext: Database {

    /// The database which is being edited
    private unowned let database: Database

    /// The modified values
    ///
    /// - Note: Contains only the most recent values of the edits
    private var modifiedValues: [Path: (value: Any, setter: () -> Void)] = [:]

    init(database: Database) {
        self.database = database
    }

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        if let edited: Value = getFromCache(path) {
            return edited

        }
        return database.get(path)
    }
    
    public func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        let setter: () -> Void = { [weak self] in
            self?.database.set(value, for: path)
        }
        // Note: Previous edits are overwritten
        modifiedValues[path] = (value, setter)
    }
    
    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        var handledIds: Set<InstanceKey> = []
        let existing: [T] = database.all(model: model) { instance, status in
            handledIds.insert(instance)
            let path = Path(model: model, instance: instance)
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

    private func getFromCache<Value: DatabaseValue>(_ path: Path) -> Value? {
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
