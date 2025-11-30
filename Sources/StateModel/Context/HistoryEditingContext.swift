import Foundation

/**
 A temporary context to perform edits to a database, which can be commited all together.
 */
public final class HistoryEditingContext: Database {

    /// The database which is being edited
    private unowned let database: HistoryDatabase

    /// The date at which the context was created
    private var contextStartDate: Date

    /// The modified values
    ///
    /// - Note: Contains only the most recent values of the edits
    private var modifiedValues: [Path: (value: Any, date: Date, setter: () -> Void)] = [:]

    init(database: HistoryDatabase, date: Date) {
        self.database = database
        self.contextStartDate = date
    }

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        let previous: Timestamped<Value>? = database.get(path, at: contextStartDate)
        guard let edited: Timestamped<Value> = getFromCache(path) else {
            return previous?.value

        }
        guard let previous else {
            return edited.value
        }
        guard edited.date >= previous.date else {
            return previous.value // Previous value is closer to requested date
        }
        return edited.value // Edited value is closer to requested date
    }
    
    public func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        let setter: () -> Void = { [weak self] in
            guard let self else { return }
            self.database.set(value, for: path, at: self.contextStartDate)
        }
        // Note: Previous edits are overwritten
        // TODO: Store all edits
        modifiedValues[path] = (value, contextStartDate, setter)
    }

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        var handledIds: Set<InstanceKey> = []
        let existing: [T] = database.all(model: model, at: contextStartDate) { instance, status, timestamp in
            handledIds.insert(instance)
            let path = Path(model: model, instance: instance)
            guard let edited: Timestamped<InstanceStatus> = getFromCache(path),
                  edited.date >= timestamp else {
                return predicate(instance, status)
            }
            return predicate(instance, edited.value)
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

    private func getFromCache<Value: DatabaseValue>(_ path: Path) -> Timestamped<Value>? {
        guard let changed = modifiedValues[path] else {
            return nil
        }
        guard let value = changed.value as? Value else {
            return nil
        }
        return .init(value: value, date: changed.date)
    }

    /**
     Write all changes made in the context to the database.

     If additional changes were made to the database in the meantime,
     then the changes will be merged together,
     showing only the most recent values for each path.
     */
    public func commitChanges() {
        for value in modifiedValues.values {
            value.setter()
        }
        discardChanges()
        moveToCurrentState()
    }

    /**
     Move the context snapshot to include all updates to the database until now.

     This does not remove any changes made during the edit, but it may hide them if the same paths have been updated in the database.
     */
    public func moveToCurrentState() {
        contextStartDate = Date()
    }

    /**
     Discard all changes made in this context.

     - Note: This does not move the context snapshot to the current date.
     */
    public func discardChanges() {
        modifiedValues.removeAll()
    }
}
