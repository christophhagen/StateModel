import Foundation

/**
 A view of a database at a specific instance in time.
 */
public final class HistoryView: Database {

    /// The database that is accessed
    private let wrapped: HistoryDatabase

    /// The date at which the database is accessed
    private var date: Date

    /**
     Create a new history view
     */
    init(wrapped: HistoryDatabase, at date: Date) {
        self.wrapped = wrapped
        self.date = date
    }

    public func get<Value: DatabaseValue>(_ path: Path) -> Value? {
        wrapped.get(path, at: date)?.value
    }

    public func set<Value: DatabaseValue>(_ value: Value, for path: Path) {
        // Note: In a history view, we don't allow writing to the database, and just ignore all updates
        // wrapped.set(value, model: model, instance: instance, property: property, at: date)
    }

    public func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
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
