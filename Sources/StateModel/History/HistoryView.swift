import Foundation

/**
 A view of a database at a specific instance in time.
 */
public final class HistoryView<ModelKey,InstanceKey,PropertyKey>: Database<ModelKey,InstanceKey,PropertyKey> where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    /// The database that is accessed
    private let wrapped: HistoryDatabase<ModelKey,InstanceKey,PropertyKey>

    /// The date at which the database is accessed
    private var date: Date

    /**
     Create a new history view
     */
    init(wrapped: HistoryDatabase<ModelKey, InstanceKey, PropertyKey>, at date: Date) {
        self.wrapped = wrapped
        self.date = date
    }

    public override func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> Value? where Value : Decodable, Value : Encodable {
        wrapped.get(model: model, instance: instance, property: property, at: date)?.value
    }

    public override func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey) where Value : Decodable, Value : Encodable {
        // Note: In a history view, we don't allow writing to the database, and just ignore all updates
        // wrapped.set(value, model: model, instance: instance, property: property, at: date)
    }

    public override func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        wrapped.all(model: model, at: date) { instance, status, _ in
            predicate(instance, status)
        }
    }

    /**
     Move the history view to the given date.
     - Parameter date: The date at which to view the database
     */
    public func moveView(to date: Date) {
        self.date = date
    }
}
