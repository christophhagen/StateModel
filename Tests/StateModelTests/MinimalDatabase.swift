import Foundation
import StateModel

/**
 A simple database implementation that only caches the latest values in memory
 */
final class MinimalDatabase<Key>: Database where Key: PathKey {

    typealias KeyPath = Path<Key, Key, Key>

    private var cache: [KeyPath: Any] = [:]

    // MARK: Properties

    func get<Value>(model: Key, instance: Key, property: Key) -> Value? where Value: Codable {
        let path = Path(model: model, instance: instance, property: property)
        return cache[path] as? Value
    }

    func set<Value>(_ value: Value, model: Key, instance: Key, property: Key) where Value: Codable {
        let path = Path(model: model, instance: instance, property: property)
        cache[path] = value
    }

    // MARK: Instances

    public func select<T>(model: ModelKey, property: PropertyKey, where predicate: (_ instanceId: InstanceKey, _ value: InstanceStatus) -> T?) -> [T] {
        cache.compactMap { (path, value) -> T? in
            guard path.model == model,
                  path.property == property,
                  let value = value as? InstanceStatus else {
                return nil
            }
            return predicate(path.instance, value)
        }
    }
}
