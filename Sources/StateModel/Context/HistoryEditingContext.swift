import Foundation

/**
 A temporary context to perform edits to a database, which can be commited all together.
 */
public final class HistoryEditingContext<ModelKey,InstanceKey,PropertyKey>: HistoryDatabase<ModelKey,InstanceKey,PropertyKey> where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    /// The database which is being edited
    private unowned let database: HistoryDatabase<ModelKey,InstanceKey,PropertyKey>

    /// The date at which the context was created
    private var contextStartDate: Date

    /// The modified values
    ///
    /// - Note: Contains only the most recent values of the edits
    private var modifiedValues: [Path<ModelKey, InstanceKey, PropertyKey>: (value: Any, date: Date, setter: () -> Void)] = [:]

    init(database: HistoryDatabase<ModelKey,InstanceKey,PropertyKey>, date: Date) {
        self.database = database
        self.contextStartDate = date
    }

    public override func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey, at date: Date?) -> (value: Value, date: Date)? where Value : Decodable, Value : Encodable {
        let previous: (value: Value, date: Date)? = database.get(model: model, instance: instance, property: property, at: contextStartDate)
        guard let edited: (value: Value, date: Date) = getFromCache(model: model, instance: instance, property: property) else {
            return previous

        }
        guard let previous else {
            return edited
        }
        guard edited.date >= previous.date else {
            return previous // Previous value is closer to requested date
        }
        return edited // Edited value is closer to requested date
    }
    
    public override func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey, at date: Date?) where Value : Decodable, Value : Encodable {
        let timeOfChange = Date()
        let setter: () -> Void = { [weak self] in
            self?.database.set(value, model: model, instance: instance, property: property, at: timeOfChange)
        }
        let path = Path(model: model, instance: instance, property: property)
        // Note: Previous edits are overwritten
        // TODO: Store all edits
        modifiedValues[path] = (value, timeOfChange, setter)
    }
    
    public override func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        var handledIds: Set<InstanceKey> = []
        let existing: [T] = database.all(model: model, at: nil) { instance, status, timestamp in
            handledIds.insert(instance)
            guard let edited: (value: InstanceStatus, date: Date) = getFromCache(model: model, instance: instance, property: PropertyKey.instanceId),
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

    private func getFromCache<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> (value: Value, date: Date)? where Value : Decodable, Value : Encodable {
        guard let changed = modifiedValues[Path(model: model, instance: instance, property: property)] else {
            return nil
        }
        guard let value = changed.value as? Value else {
            return nil
        }
        return (value, changed.date)
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
