import Foundation
import StateModel

/**
 A simple database implementation that only caches the latest values in memory
 */
final class MinimalDatabase<Key>: Database where Key: PathKey {

    typealias KeyPath = Path<Key, Key, Key>

    private var cache: [KeyPath: Any] = [:]

    // MARK: Properties

    func get<Value>(_ keyPath: KeyPath) -> Value? where Value: Codable {
        cache[keyPath] as? Value
    }

    func set<Value>(_ value: Value, for path: KeyPath) where Value: Codable {
        cache[path] = value
    }

    // MARK: Instances

    public func select<T>(modelId: ModelKey, propertyId: PropertyKey, where predicate: (_ instanceId: InstanceKey, _ value: InstanceStatus) -> T?) -> [T] {
        cache.compactMap { (path, value) -> T? in
            guard path.model == modelId,
                  path.property == propertyId,
                  let value = value as? InstanceStatus else {
                return nil
            }
            return predicate(path.instance, value)
        }
    }
}
