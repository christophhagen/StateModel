import Foundation

/**
 A view of a database at a specific instance in time.
 */
public final class HistoryView<ModelKey,InstanceKey,PropertyKey>: Database<ModelKey,InstanceKey,PropertyKey> where ModelKey: ModelKeyType, InstanceKey: InstanceKeyType, PropertyKey: PropertyKeyType {

    unowned let wrapped: HistoryDatabase<ModelKey,InstanceKey,PropertyKey>

    private let date: Date

    init(wrapped: HistoryDatabase<ModelKey, InstanceKey, PropertyKey>, date: Date) {
        self.wrapped = wrapped
        self.date = date
    }

    public override func get<Value>(model: ModelKey, instance: InstanceKey, property: PropertyKey) -> Value? where Value : Decodable, Value : Encodable {
        wrapped.get(model: model, instance: instance, property: property, at: self.date)?.value
    }

    public override func set<Value>(_ value: Value, model: ModelKey, instance: InstanceKey, property: PropertyKey) where Value : Decodable, Value : Encodable {
        // TODO: Throw a fatal error when writing data in a history view?
        wrapped.set(value, model: model, instance: instance, property: property, at: self.date)
    }

    public override func all<T>(model: ModelKey, where predicate: (InstanceKey, InstanceStatus) -> T?) -> [T] {
        wrapped.all(model: model, at: self.date) { instance, status, _ in
            predicate(instance, status)
        }
    }
}
