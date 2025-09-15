import Foundation
import StateModel

/**
 A simple database implementation that only caches the latest values in memory
 */
final class MinimalDatabase<Key>: DatabaseProtocol where Key: PathKey {

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

    public func all<T>(model: Key, where predicate: (_ instanceId: Key, _ value: InstanceStatus) -> T?) -> [T] {
        cache.compactMap { (path, value) -> T? in
            guard path.model == model,
                  path.property == PropertyKey.instanceId,
                  let value = value as? InstanceStatus else {
                return nil
            }
            return predicate(path.instance, value)
        }
    }
}
